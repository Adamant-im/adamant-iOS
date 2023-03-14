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

extension BitcoinKit.Transaction: RawTransaction {
    var txHash: String? {
        return txID
    }
}

extension DogeWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.transfer) as? DogeTransferViewController else {
            fatalError("Can't get DogeTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal) async throws -> BitcoinKit.Transaction {
        // Prepare
        guard let wallet = self.dogeWallet else {
            throw WalletServiceError.notLogged
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
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
            let transaction = BitcoinKit.Transaction.createNewTransaction(toAddress: toAddress, amount: rawAmount, fee: fee, changeAddress: changeAddress, utxos: utxos, keys: [key])
            return transaction
        } catch {
            throw WalletServiceError.notEnoughMoney
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction) async throws {
        guard let url = DogeWalletService.nodes.randomElement()?.asURL() else {
            throw WalletServiceError.internalError(
                message: "Failed to get DOGE endpoint URL",
                error: nil
            )
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.sendTransaction())
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // MARK: Prepare params
        let txHex = transaction.serialized().hex
        
        let parameters: Parameters = [
            "rawtx": txHex
        ]
        
        // MARK: Sending request
        _ = try await withUnsafeThrowingContinuation { continuation in
            AF.request(
                endpoint,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .validate(statusCode: 200 ... 299)
            .responseJSON(queue: defaultDispatchQueue) { response in
                switch response.result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    guard let data = response.data else {
                        continuation.resume(throwing: WalletServiceError.remoteServiceError(message: error.localizedDescription))
                        return
                    }
                    let result = String(decoding: data, as: UTF8.self)
                    if result.contains("dust") && result.contains("-26") {
                        continuation.resume(throwing: WalletServiceError.dustAmountError)
                        return
                    }
                    continuation.resume(throwing: WalletServiceError.remoteServiceError(message: error.localizedDescription))
                }
            }
        }
    }
}

extension BitcoinKit.Transaction: TransactionDetails {
    static var defaultCurrencySymbol: String? { return DogeWalletService.currencySymbol }
    
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
