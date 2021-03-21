//
//  LskApiService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Lisk
import web3swift
import struct BigInt.BigUInt

class AdamantLskApiService: LskApiService {
    
    // MARK: - Constans
    static let kvsAddress = "lsk:address"
    static let defaultFee = 0.1
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    
    // MARK: - Properties
    private(set) var account: LskAccount?

    private var accountApi: Accounts!
    private var transactionApi: Transactions!
    
    init() {
        accountApi = Accounts(client: .testnet)
        transactionApi = Transactions(client: .testnet)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.account = nil
        }
    }
    
    func createTransaction(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<LocalTransaction>) -> Void) {
        if let keys = self.account?.keys {
            do {
                let transaction = LocalTransaction(.transfer, lsk: amount, recipientId: address)
                let signedTransaction = try transaction.signed(keyPair: keys)
                
                completion(.success(signedTransaction))
            } catch {
                completion(.failure(.internalError(message: error.localizedDescription, error: error)))
            }
        }
    }
    
    func sendTransaction(transaction: LocalTransaction, completion: @escaping (ApiServiceResult<String>) -> Void) {
        transactionApi.submit(signedTransaction: transaction) { response in
            switch response {
            case .success(let result):
                print(result.data.hashValue)
                print(result.data.message)
                
                completion(.success(transaction.id ?? ""))
            case .error(let error):
                print("ERROR: " + error.message)
                completion(.failure(.internalError(message: error.message, error: nil)))
            }
        }
    }
    
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void) {
        if let keys = self.account?.keys {
            
            do {
                let transaction = LocalTransaction(.transfer, lsk: amount, recipientId: address)
                let signedTransaction = try transaction.signed(keyPair: keys)
                
                transactionApi.submit(signedTransaction: signedTransaction) { response in
                    switch response {
                    case .success(let result):
                        print(result.data.hashValue)
                        print(result.data.message)
                        
                        if let id = signedTransaction.id {
                            let result = ["type": "lsk_transaction", "amount": "\(amount)", "hash": id, "comments":""]
                            
                            do {
                                let data = try JSONEncoder().encode(result)
                                guard let raw = String(data: data, encoding: String.Encoding.utf8) else {
                                    return
                                }
                                completion(.success(raw))
                            } catch {
                                completion(.failure(.internalError(message: "LSK Wallet: Send - wrong data issue", error: nil)))
                            }
                        } else {
                            completion(.failure(.internalError(message: "LSK Wallet: Send - wrong data issue", error: nil)))
                        }
                        
                        
                    case .error(let error):
                        print("ERROR: " + error.message)
                        completion(.failure(.internalError(message: error.message, error: nil)))
                    }
                }
            } catch {
                completion(.failure(.internalError(message: error.localizedDescription, error: error)))
            }
        }
    }
    
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Transactions.TransactionModel]>) -> Void) {
        if let address = self.account?.address {
            transactionApi.transactions(senderIdOrRecipientId: address, limit: 100, offset: 0, sort: APIRequest.Sort("timestamp", direction: .descending)) { (response) in
                switch response {
                case .success(response: let result):
                    completion(.success(result.data))
                    break
                case .error(response: let error):
                    print("ERROR: " + error.message)
                    completion(.failure(.internalError(message: error.message, error: nil)))
                    break
                }
            }
        }
    }
    
    func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Transactions.TransactionModel>) -> Void) {
        transactionApi.transactions(id: hash, limit: 1, offset: 0) { (response) in
            switch response {
            case .success(response: let result):
                if let transaction = result.data.first {
                    completion(.success(transaction))
                } else {
                    completion(.failure(.internalError(message: "No transaction", error: nil)))
                }
                break
            case .error(response: let error):
                print("ERROR: " + error.message)
                completion(.failure(.internalError(message: error.message, error: nil)))
                break
            }
        }
    }
    
    // MARK: - Tools
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void) {
        guard let address = self.account?.address else {
            completion(.failure(.notLogged))
            return
        }
        
        accountApi.accounts(address: address) { (response) in
            switch response {
            case .success(response: let response):
                if let account = response.data.first {
                    let balance = BigUInt(account.balance ?? "0") ?? BigUInt(0)
                    
                    self.account?.balance = balance
                    self.account?.balanceString = self.fromRawLsk(value: balance)
                    
                    if let balanceString = self.account?.balanceString, let balance = Double(balanceString) {
                        self.account?.balanceString = "\(balance)"
                    }
                }
                
                completion(.success("\(self.account?.balanceString ?? "--") LSK"))
                
            case .error(response: let error):
                print(error)
                completion(.failure(.serverError(error: error.message)))
            }
        }
    }
    
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: AdamantLskApiService.kvsAddress, sender: address, completion: completion)
    }
    
    func fromRawLsk(value: BigUInt) -> String {
        if let formattedAmount = Web3.Utils.formatToPrecision(value, numberDecimals: 8, formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false) {
            return formattedAmount
        } else {
            return "--"
        }
    }
    
    func toRawLsk(value: Double) -> String {
        if let formattedAmount = Web3.Utils.parseToBigUInt("\(value)", decimals: 8) {
            return "\(formattedAmount)"
        } else {
            return "--"
        }
    }
    
    private static let addressRegexString = "^([0-9]{2,22})L$"
    private static let addressRegex = try! NSRegularExpression(pattern: addressRegexString, options: [])
    private static let maxAddressNumber = BigUInt("18446744073709551615")
    
    /// Rules are simple:
    ///
    /// - Tailing uppercase L
    /// - From 2 to 22 numbers
    /// - Address number lower 18446744073709551615
    /// - No leading or trailing whitespaces
    static func validateAddress(address: String) -> AdamantUtilities.AddressValidationResult {
        let value = address.replacingOccurrences(of: "L", with: "")
        
        if validate(string: address, with: addressRegex), let number = BigUInt(value), number < maxAddressNumber {
            return .valid
        } else {
            return .invalid
        }
    }
    
    private static func validate(string: String, with regex: NSRegularExpression) -> Bool {
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        return matches.count == 1
    }
}
