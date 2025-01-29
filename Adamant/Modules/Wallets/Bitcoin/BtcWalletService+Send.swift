//
//  BtcWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 08/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Alamofire
import BitcoinKit

extension BtcWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    // MARK: Create & Send
    func createTransaction(
        recipient: String,
        amount: Decimal,
        fee: Decimal,
        comment: String?
    ) async throws -> BitcoinKit.Transaction {
        // MARK: 1. Prepare
        guard let wallet = self.btcWallet else {
            throw WalletServiceError.notLogged
        }
        
        let key = wallet.privateKey
        
        guard let toAddress = try? addressConverter.convert(address: recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * BtcWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: fee * BtcWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions

        let utxos = try await getUnspentTransactions()
        
        // MARK: 3. Check if we have enought money
        
        let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
        guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
            throw WalletServiceError.notEnoughMoney
        }
        
        // MARK: 4. Create local transaction
        
        let transaction = btcTransactionFactory.createTransaction(
            toAddress: toAddress,
            amount: rawAmount,
            fee: fee,
            changeAddress: wallet.addressEntity,
            utxos: utxos,
            lockTime: 0,
            keys: [key]
        )
        
        return transaction
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction) async throws {
        // MARK: Prepare params
        
        let txHex = transaction.serialized().hex
        
        // MARK: Sending request
        let responseData = try await btcApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(
                origin: origin,
                path: BtcApiCommands.sendTransaction(),
                method: .post,
                parameters: [String.empty: txHex],
                encoding: .bodyString
            )
        }.get()

        let response = String(decoding: responseData, as: UTF8.self)
        guard response != transaction.txId else { return }
        throw WalletServiceError.remoteServiceError(message: response)
    }
    
    func getUnspentTransactions() async throws -> [UnspentTransaction] {
        guard let wallet = self.btcWallet else {
            throw WalletServiceError.notLogged
        }
        
        let address = wallet.address
        let parameters = ["noCache": "1"]
        
        let responseData = try await btcApiService.request(waitsForConnectivity: false) { core, origin in
            await core.sendRequest(
                origin: origin,
                path: BtcApiCommands.getUnspentTransactions(for: address),
                method: .get,
                parameters: parameters,
                encoding: .url
            )
        }.get()
        
        guard
            let items = try? Self.jsonDecoder.decode(
                [BtcUnspentTransactionResponse].self,
                from: responseData
            )
        else {
            throw WalletServiceError.internalError(message: "BTC Wallet: not valid response", error: nil)
        }
        
        var utxos = [UnspentTransaction]()
        for item in items {
            guard item.status.confirmed else {
                continue
            }
            
            let value = NSDecimalNumber(decimal: item.value).uint64Value
            
            let lockScript = wallet.addressEntity.lockingScript
            let txHash = Data(hex: item.txId).map { Data($0.reversed()) } ?? Data()
            let txIndex = item.vout
            
            let unspentOutput = TransactionOutput(value: value, lockingScript: lockScript)
            let unspentOutpoint = TransactionOutPoint(hash: txHash, index: txIndex)
            let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)
            
            utxos.append(utxo)
        }
        
        return utxos
    }
}
