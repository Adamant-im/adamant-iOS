//
//  LskApiService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import BigInt
import Lisk
import Ed25519
import web3swift

// MARK: - Notifications
extension Notification.Name {
    struct LskApiService {
        /// Raised when user has logged out.
        static let userLoggedOut = Notification.Name("adamant.lskApiService.userHasLoggedOut")
        
        /// Raised when user has successfully logged in.
        static let userLoggedIn = Notification.Name("adamant.lskApiService.userHasLoggedIn")
        
        private init() {}
    }
}

struct LskAccount {
    let keys: KeyPair
    let address: String
    var balance: BigUInt?
    var balanceString: String?
}

class LskApiService: LskApiServiceProtocol {
    
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
    
    func newAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<LskAccount>) -> Void) {
        do {
            let keys = try Crypto.keyPair(fromPassphrase: passphrase)
            let address = Crypto.address(fromPublicKey: keys.publicKeyString)
            let account = LskAccount(keys: keys, address: address, balance: BigUInt(0), balanceString: "0 LSK")
            self.account = account
//            print(address)
            completion(.success(account))
        } catch {
            print("\(error)")
            completion(.failure(.accountNotFound))
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name.LskApiService.userLoggedIn, object: self)
        
        if let account = self.account, let address = self.accountService.account?.address, let keypair = self.accountService.keypair {
            self.getLskAddress(byAdamandAddress: address) { (result) in
                switch result {
                case .success(let value):
                    if value == nil {
                        guard let loggedAccount = self.accountService.account else {
                            DispatchQueue.main.async {
                                completion(.failure(.notLogged))
                            }
                            return
                        }
                        
                        guard loggedAccount.balance >= AdamantApiService.KVSfee else {
                            DispatchQueue.main.async {
                                completion(.failure(.internalError(message: "LSK Wallet: Not enought ADM to save address to KVS", error: nil)))
                            }
                            return
                        }
                        
                        self.apiService.store(key: LskApiService.kvsAddress, value: account.address, type: StateType.keyValue, sender: address, keypair: keypair, completion: { (result) in
                            switch result {
                            case .success(let transactionId):
                                print("SAVED LSK in KVS: \(transactionId)")
                                break
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    completion(.failure(.internalError(message: "LSK Wallet: fail to save address to KVS", error: error)))
                                }
                                break
                            }
                        })
                    } else {
                        print("FOUND LSK in KVS: \(value!)")
                    }
                    break
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(.internalError(message: "LSK Wallet: fail to get address from KVS", error: error)))
                    }
                    break
                }
            }
        }
    }
    
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void) {
        if let keys = self.account?.keys {
            transactionApi.transfer(lsk: amount, to: address, keyPair: keys) { response in
                switch response {
                case .success(let result):
                    print(result.data.hashValue)
                    print(result.data.message)
                    completion(.success(result.data.message))
                case .error(let error):
                    print("ERROR: " + error.message)
                    completion(.failure(.internalError(message: error.message, error: nil)))
                }
            }
        }
    }
    
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Transactions.TransactionModel]>) -> Void) {
        if let address = self.account?.address {
            transactionApi.transactions(senderIdOrRecipientId: address, limit: 100, offset: 0) { (response) in
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
    
    // MARK: - Tools
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void) {
        if let address = self.account?.address {
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
                    
                    break
                case .error(response: let error):
                    print(error)
                    completion(.failure(.serverError(error: error.message)))
                    break
                }
            }
        } else {
            completion(.failure(.internalError(message: "LSK Wallet: not found", error: nil)))
        }
    }
    
    func getLskAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: LskApiService.kvsAddress, sender: address, completion: completion)
    }
    
    func fromRawLsk(value: BigUInt) -> String {
        if let formattedAmount = Web3.Utils.formatToPrecision(value, numberDecimals: 8, formattingDecimals: 8, decimalSeparator: ".", fallbackToScientific: false) {
            return formattedAmount
        } else {
            return "--"
        }
    }
    
    func toRawLsk(value: Double) -> BigInt {
        return BigInt(value) * BigInt(10).power(8)
    }
    
    private static let addressRegexString = "^([0-9]{2,22})L$"
    private static let addressRegex = try! NSRegularExpression(pattern: addressRegexString, options: [])
    private static let maxAddressNumber = BigUInt("18446744073709551615")!
    
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
