//
//  DashWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import BitcoinKit
import Alamofire

extension DashWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    // MARK: Create & Send
    func create(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        guard let lastTransaction = self.lastTransactionId else {
            return try await  createTransaction(recipient: recipient, amount: amount)
        }
        
        let transaction = try await getTransaction(by: lastTransaction)
        
        guard let confirmations = transaction.confirmations,
              confirmations >= 1
        else {
            throw WalletServiceError.internalError(message: "WAIT_FOR_COMPLETION", error: nil)
        }
        
        return try await createTransaction(recipient: recipient, amount: amount)
    }
    
    func createTransaction(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        // MARK: 1. Prepare
        guard let wallet = self.dashWallet else {
            throw WalletServiceError.notLogged
        }
        
        let key = wallet.privateKey
        
        guard let toAddress = try? addressConverter.convert(address: recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * DashWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * DashWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions

        let utxos = try await getUnspentTransactions()
        
        // MARK: 3. Check if we have enought money
        let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
        guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
            throw WalletServiceError.notEnoughMoney
        }
        
        // MARK: 4. Create local transaction
        let transaction = BitcoinKit.Transaction.createNewTransaction(
            toAddress: toAddress,
            amount: rawAmount,
            fee: fee,
            changeAddress: wallet.addressEntity,
            utxos: utxos,
            keys: [key]
        )
        return transaction
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction) async throws {
        let txHex = transaction.serialized().hex
        
        let response: BTCRPCServerResponce<String> = try await dashApiService.request { core, node in
            await core.sendRequestJson(
                node: node,
                path: .empty,
                method: .post,
                parameters: DashSendRawTransactionDTO(txHex: txHex),
                encoding: .json
            )
        }.get()
        
        if response.result != nil {
            lastTransactionId = transaction.txID
        } else if let error = response.error?.message {
            if error.lowercased().contains("16: tx-txlock-conflict") {
                throw WalletServiceError.internalError(
                    message: String.adamant.sharedErrors.walletFrezzed,
                    error: nil
                )
            } else {
                throw WalletServiceError.internalError(message: error, error: nil)
            }
        } else {
            throw WalletServiceError.internalError(message: "DASH Wallet: not valid response", error: nil)
        }
    }
}
