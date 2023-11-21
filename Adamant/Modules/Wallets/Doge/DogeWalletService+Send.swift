//
//  DogeWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import BitcoinKit
import Alamofire
import CommonKit

extension BitcoinKit.Transaction: RawTransaction {
    var txHash: String? {
        return txID
    }
}

extension DogeWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        // Prepare
        guard let wallet = self.dogeWallet else {
            throw WalletServiceError.notLogged
        }
        
        let key = wallet.privateKey
        
        guard let toAddress = try? addressConverter.convert(address: recipient) else {
            throw WalletServiceError.accountNotFound
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * DogeWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * DogeWalletService.multiplier).uint64Value
        
        // Search for unspent transactions
        do {
            let utxos = try await getUnspentTransactions()
            
            // Check if we have enought money
            let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
            guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
                throw WalletServiceError.notEnoughMoney
            }
            
            // Create local transaction
            let transaction = BitcoinKit.Transaction.createNewTransaction(
                toAddress: toAddress,
                amount: rawAmount,
                fee: fee,
                changeAddress: wallet.addressEntity,
                utxos: utxos,
                keys: [key]
            )
            return transaction
        } catch {
            throw WalletServiceError.notEnoughMoney
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction) async throws {
        let txHex = transaction.serialized().hex
        
        _ = try await dogeApiService.api.request { core, node in
            let response: APIResponseModel = await core.apiCore.sendRequestBasic(
                node: node,
                path: DogeApiCommands.sendTransaction(),
                method: .post,
                parameters: ["rawtx": txHex],
                encoding: .json
            )
            
            guard
                !(200 ... 299).contains(response.code ?? .zero),
                let dataString = response.data.map({ String(decoding: $0, as: UTF8.self) }),
                dataString.contains("dust"),
                dataString.contains("-26")
            else { return response.result.mapError { $0.asWalletServiceError() } }
            
            return .failure(.dustAmountError)
        }.get()
    }
}

extension BitcoinKit.Transaction: TransactionDetails {
    var defaultCurrencySymbol: String? { DogeWalletService.currencySymbol }
    
    var txId: String {
        return txID
    }
    
    var dateValue: Date? {
        switch lockTime {
        case 1..<500000000:
            return nil
        case 500000000...:
            return Date(timeIntervalSince1970: TimeInterval(lockTime))
        default:
            return nil
        }
    }
    
    var amountValue: Decimal? {
        return Decimal(outputs[0].value) / Decimal(100000000)
    }
    
    var feeValue: Decimal? {
        return nil
    }
    
    var confirmationsValue: String? {
        return "0"
    }
    
    var blockValue: String? {
        return nil
    }
    
    var isOutgoing: Bool {
        return true
    }
    
    var blockHeight: UInt64? {
        return nil
    }
    
    var transactionStatus: TransactionStatus? {
        return .pending
    }
    
    var senderAddress: String {
        return ""
    }
    
    var recipientAddress: String {
        return ""
    }
}
