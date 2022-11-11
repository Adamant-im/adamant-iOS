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
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<BitcoinKit.Transaction>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = self.dogeWallet else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
            completion(.failure(error: .accountNotFound))
            return
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * DogeWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * DogeWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions
        getUnspentTransactions { result in
            switch result {
            case .success(let utxos):
                // MARK: 3. Check if we have enought money
                let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
                guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
                    completion(.failure(error: .notEnoughMoney))
                    break
                }
                
                // MARK: 4. Create local transaction
                let transaction = BitcoinKit.Transaction.createNewTransaction(toAddress: toAddress, amount: rawAmount, fee: fee, changeAddress: changeAddress, utxos: utxos, keys: [key])
                completion(.success(result: transaction))
                
            case .failure:
                completion(.failure(error: .notEnoughMoney))
            }
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        guard let url = AdamantResources.dogeServers.randomElement() else {
            fatalError("Failed to get DOGE endpoint URL")
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
        AF.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                if let result = data as? [String: Any], let txid = result["txid"] as? String {
                    completion(.success(result: txid))
                } else {
                    completion(.failure(error: .internalError(message: "DOGE Wallet: not valid response", error: nil)))
                }
                
            case .failure(let error):
                guard let data = response.data else {
                    completion(.failure(error: .remoteServiceError(message: error.localizedDescription)))
                    return
                }
                let result = String(decoding: data, as: UTF8.self)
                if result.contains("dust") && result.contains("-26") {
                    completion(.failure(error: .dustAmountError))
                    return
                }
                completion(.failure(error: .remoteServiceError(message: error.localizedDescription)))
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
