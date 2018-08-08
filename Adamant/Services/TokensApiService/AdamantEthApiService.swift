//
//  EthApiService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 16/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import BigInt
import Alamofire

class AdamantEthApiService: EthApiService {
    
    // MARK: - Constans
    static let transferGas = 21000
    static let kvsAddress = "eth:address"
    static let defaultGasPrice = 20000000000 // 20 Gwei
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    
    // MARK: - Properties
    var apiUrl: String
    var web3: web3!
    
    var transactionsHistoryService: TransactionsHistory!
    
    private(set) var account: EthAccount?
    
    // MARK: - Initialization
    
    init(apiUrl: String) {
        self.apiUrl = apiUrl
        
        if let url = URL(string: self.apiUrl), let web3 = Web3.new(url) {
            self.web3 = web3
        } else {
            print("Unable init Web3")
            return
        }
        
        let gasPriceResult = self.web3.eth.getGasPrice()
        guard case .success(let gasPrice) = gasPriceResult else { return }
        
        print("ETH Server gas Price: \(gasPrice)")
        
        guard let network = self.web3.provider.network else {
            print("Unable get ETH Server network")
            self.transactionsHistoryService = TransactionsHistory(network: "")
            return
        }
        print("ETH Server network: \(network)")
        
        self.transactionsHistoryService = TransactionsHistory(network: "\(network)")
    }
    
    func newAccount(byPassphrase passphrase: String, completion: @escaping (ApiServiceResult<EthAccount>) -> Void) {
        DispatchQueue.global().async {
            guard let keystore = try? BIP32Keystore(mnemonics: passphrase,
                                                    password: "",
                                                    mnemonicsPassword: "",
                                                    language: .english),
                let wallet = keystore else {
                    DispatchQueue.main.async {
                        completion(.failure(.internalError(message: "ETH Wallet: fail to create Keystore", error: nil)))
                    }
                    return
            }
            
			self.account = EthAccount(wallet: wallet, address: wallet.addresses?.first?.address, balance: BigUInt(0), balanceString: "0")
            if let account = self.account {
                NotificationCenter.default.post(name: Notification.Name.EthApiService.userLoggedIn, object: self)
                DispatchQueue.main.async {
                    completion(.success(account))
                }
                
                self.getBalance({ _ in })
                
                if let address = self.accountService.account?.address, let keypair = self.accountService.keypair {
                    self.getEthAddress(byAdamandAddress: address) { (result) in
                        switch result {
                        case .success(let value):
							guard value == nil else { // value already saved in KVS
								return
							}
							
							guard let loggedAccount = self.accountService.account else {
								DispatchQueue.main.async {
									completion(.failure(.notLogged))
								}
								return
							}
							
							guard loggedAccount.balance >= AdamantApiService.KvsFee else {
								DispatchQueue.main.async {
									completion(.failure(.internalError(message: "ETH Wallet: Not enought ADM to save address to KVS", error: nil)))
								}
								return
							}
							
							self.apiService.store(key: AdamantEthApiService.kvsAddress, value: account.address!, type: StateType.keyValue, sender: address, keypair: keypair, completion: { (result) in
								switch result {
								case .success(let transactionId):
									print("SAVED: \(transactionId)")
									break
								case .failure(let error):
									DispatchQueue.main.async {
										completion(.failure(.internalError(message: "ETH Wallet: fail to save address to KVS", error: error)))
									}
								}
							})
							
                        case .failure(let error):
                            DispatchQueue.main.async {
                                completion(.failure(.internalError(message: "ETH Wallet: fail to get address from KVS", error: error)))
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: fail to create Account", error: nil)))
                }
            }
        }
    }
    func createTransaction(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<TransactionIntermediate>) -> Void) {
        DispatchQueue.global().async {
            guard let destinationEthAddress = EthereumAddress(address) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - invalid destination address", error: nil)))
                }
                return
            }
            guard let amount = Web3.Utils.parseToBigUInt("\(amount)", units: .eth) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - invalid amount format", error: nil)))
                }
                return
            }
            
            guard let ethAddressFrom = self.account?.wallet.addresses?.first else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - no address found", error: nil)))
                }
                return
            }
            
            guard let keystore = self.account?.wallet else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - no keystore found", error: nil)))
                }
                return
            }
            
            self.web3.addKeystoreManager(KeystoreManager([keystore]))
            var options = Web3Options.defaultOptions()
            //            options.gasLimit = BigUInt(gasLimit)
            options.from = ethAddressFrom
            options.value = BigUInt(amount)
            guard let contract = self.web3.contract(Web3.Utils.coldWalletABI, at: destinationEthAddress) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - contract loading error", error: nil)))
                }
                return
            }
            
            guard let estimatedGas = contract.method(options: options)?.estimateGas(options: nil).value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - retrieving estimated gas error", error: nil)))
                }
                return
            }
            options.gasLimit = estimatedGas
            guard let gasPrice = self.web3.eth.getGasPrice().value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - retrieving gas price error", error: nil)))
                }
                return
            }
            options.gasPrice = gasPrice
            guard let intermediate = contract.method(options: options) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - create transaction issue", error: nil)))
                }
                return
            }
            
            
            DispatchQueue.main.async {
                completion(.success(intermediate))
            }
        }
    }
    
    func sendTransaction(transaction: TransactionIntermediate, completion: @escaping (ApiServiceResult<String>) -> Void) {
        DispatchQueue.global().async {
            let sendResult = transaction.send(password: "", options: nil)
            
            guard let sendValue = sendResult.value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - sending transaction error", error: nil)))
                }
                return
            }
            
            guard let hash = sendValue["txhash"] else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - fail to get transaction hash", error: nil)))
                }
                return
            }
            DispatchQueue.main.async {
                completion(.success(hash))
            }
        }
    }
    
    func sendFunds(toAddress address: String, amount: Double, completion: @escaping (ApiServiceResult<String>) -> Void) {
        DispatchQueue.global().async {
            guard let destinationEthAddress = EthereumAddress(address) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - invalid destination address", error: nil)))
                }
                return
            }
            guard let amount = Web3.Utils.parseToBigUInt("\(amount)", units: .eth) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - invalid amount format", error: nil)))
                }
                return
            }
            
            guard let ethAddressFrom = self.account?.wallet.addresses?.first else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - no address found", error: nil)))
                }
                return
            }
            
            guard let keystore = self.account?.wallet else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - no keystore found", error: nil)))
                }
                return
            }
            
            self.web3.addKeystoreManager(KeystoreManager([keystore]))
            var options = Web3Options.defaultOptions()
//            options.gasLimit = BigUInt(gasLimit)
            options.from = ethAddressFrom
            options.value = BigUInt(amount)
            guard let contract = self.web3.contract(Web3.Utils.coldWalletABI, at: destinationEthAddress) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - contract loading error", error: nil)))
                }
                return
            }
            
            guard let estimatedGas = contract.method(options: options)?.estimateGas(options: nil).value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - retrieving estimated gas error", error: nil)))
                }
                return
            }
            options.gasLimit = estimatedGas
            guard let gasPrice = self.web3.eth.getGasPrice().value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - retrieving gas price error", error: nil)))
                }
                return
            }
            options.gasPrice = gasPrice
            guard let transaction = contract.method(options: options) else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - create transaction issue", error: nil)))
                }
                return
            }
            
            guard let sendResult = transaction.send(password: "", options: nil).value else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - sending transaction error", error: nil)))
                }
                return
            }
            
            guard let hash = sendResult["txhash"] else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - fail to get transaction hash", error: nil)))
                }
                return
            }
            
            let result = ["type": "eth_transaction", "amount": "\(amount)", "hash": hash, "comments":""]
            
            do {
                let data = try JSONEncoder().encode(result)
                guard let raw = String(data: data, encoding: String.Encoding.utf8) else {
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.success(raw))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: Send - wrong data issue", error: nil)))
                }
            }
        }
    }
    
    func getTransactions(_ completion: @escaping (ApiServiceResult<[EthTransaction]>) -> Void) {
        if let address = self.account?.address {
            transactionsHistoryService.getTransactionsHistory(address: address, completion: completion)
        } else {
            completion(.failure(.internalError(message: "ETH Wallet: not found", error: nil)))
        }
    }
    
    func getTransaction(byHash hash: String, completion: @escaping (ApiServiceResult<Web3EthTransaction>) -> Void) {
        DispatchQueue.global().async {
            let result = self.web3.eth.getTransactionDetails(hash)
            switch result {
            case .success(let transaction):
                if let number = transaction.blockNumber {
                    let resultBlockNumber = self.web3.eth.getBlockNumber()
                    guard case .success(let blockNumber) = resultBlockNumber else {
                        DispatchQueue.main.async {
                            completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: nil)))
                        }
                        return
                    }
                    
                    let result = self.web3.eth.getBlockByNumber(number)
                    guard case .success(let block) = result else {
                        DispatchQueue.main.async {
                            completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: blockNumber)))
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: block, lastBlockNumber: blockNumber)))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.success(Web3EthTransaction(transaction: transaction.transaction, transactionBlock: nil, lastBlockNumber: nil)))
                    }
                }
                break
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: fail to load transaction details", error: error)))
                }
                break
            }
        }
    }
    
    // MARK: - Tools
    
    func getBalance(_ completion: @escaping (ApiServiceResult<String>) -> Void) {
		guard let account = account, let walletAddress = account.wallet.addresses?.first else {
			completion(.failure(.internalError(message: "ETH Wallet: not found", error: nil)))
			return
		}
		
        if let walletAddress = self.account?.wallet.addresses?.first {
            self.getBalance(byAddress: walletAddress) { (result) in
                switch result {
                case .success(let balance):
                    self.account?.balance = balance
                    
                    if let formattedAmount = Web3.Utils.formatToEthereumUnits(balance,
                                                                              toUnits: .eth,
                                                                              decimals: 8,
                                                                              fallbackToScientific: true), let amount = Double(formattedAmount) {
                        self.account?.balanceString = formattedAmount
                        completion(.success("\(amount) ETH"))
                    } else {
                        completion(.failure(.internalError(message: "ETH Wallet: fail to get balance amount", error: nil)))
                    }
                    break
                case .failure(let error):
                    completion(.failure(.internalError(message: "ETH Wallet: Can't load balance", error: error)))
                }
            }
        } else {
            completion(.failure(.internalError(message: "ETH Wallet: not found", error: nil)))
        }
    }
    
    func getBalance(byAddress address: String, completion: @escaping (ApiServiceResult<String>) -> Void) {
        if let walletAddress = EthereumAddress(address) {
            self.getBalance(byAddress: walletAddress) { (result) in
                switch result {
                case .success(let balance):
                    if let formattedAmount = Web3.Utils.formatToEthereumUnits(balance,
                                                                              toUnits: .eth,
                                                                              decimals: 8,
                                                                              fallbackToScientific: true), let amount = Double(formattedAmount)  {
                        completion(.success("\(amount) ETH"))
                    } else {
                        completion(.failure(.internalError(message: "ETH Wallet: fail to get balance amount", error: nil)))
                    }
                    break
                case .failure(let error):
                    completion(.failure(.internalError(message: "ETH Wallet: Can't load balance", error: error)))
                }
            }
        } else {
            completion(.failure(.internalError(message: "ETH Wallet: not found", error: nil)))
        }
    }
    
    func getEthAddress(byAdamandAddress address: String, completion: @escaping (ApiServiceResult<String?>) -> Void) {
        apiService.get(key: AdamantEthApiService.kvsAddress, sender: address) { (result) in
            switch result {
            case .success(let value):
                if let value = value {
                    completion(.success(value))
                } else {
                    completion(.success(nil))
                }
                break
            case .failure(let error):
                completion(.failure(.internalError(message: "ETH Wallet: fail to get address from KVS", error: error)))
                break
            }
        }
    }
    
    // MARK: - Private
    func getBalance(byAddress address: EthereumAddress, completion: @escaping (ApiServiceResult<BigUInt>) -> Void) {
        DispatchQueue.global().async {
            let balanceResult = self.web3.eth.getBalance(address: address)
            guard case .success(let balance) = balanceResult else {
                DispatchQueue.main.async {
                    completion(.failure(.internalError(message: "ETH Wallet: fail to get balance", error: nil)))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(balance))
            }
        }
    }
}

// MARK: - Transactions History API

class TransactionsHistory {
    private var networkSuffix = ""
    private var baseUrl: String { return "https://api\(networkSuffix).etherscan.io/api" }
    
    init(network: String) {
        if network != "\(Networks.Mainnet)" {
            networkSuffix = "-\(network)"
        }
    }
    
    private let defaultResponseDispatchQueue = DispatchQueue(label: "com.adamant.response-queue", qos: .utility, attributes: [.concurrent])
    
    private func buildUrl(queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard let url = URL(string: baseUrl), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AdamantApiService.InternalError.endpointBuildFailed
        }
        
        components.queryItems = queryItems
        
        return try components.asURL()
    }
    
    func getTransactionsHistory(address: String, page: Int = 1, size: Int = 50, completion: @escaping (ApiServiceResult<[EthTransaction]>) -> Void) {
        let queryItems: [URLQueryItem] = [URLQueryItem(name: "module", value: "account"),
                                          URLQueryItem(name: "action", value: "txlist"),
                                          URLQueryItem(name: "address", value: address),
                                          URLQueryItem(name: "page", value: "\(page)"),
                                          URLQueryItem(name: "offset", value: "\(size)"),
                                          URLQueryItem(name: "sort", value: "desc")
//            ,URLQueryItem(name: "apikey", value: "YourApiKeyToken")
        ]
        
        let endpoint: URL
        do {
            endpoint = try buildUrl(queryItems: queryItems)
        } catch {
            let err = AdamantApiService.InternalError.endpointBuildFailed.apiServiceErrorWith(error: error)
            completion(.failure(err))
            return
        }
        
        Alamofire.request(endpoint).responseData(queue: defaultResponseDispatchQueue) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let model: EthResponse = try JSONDecoder().decode(EthResponse.self, from: data)
                        
                        if model.status == 1 {
                            completion(.success(model.result))
                        } else {
                           completion(.failure(.internalError(message: model.message, error: nil)))
                        }
                    } catch {
                       completion(.failure(.internalError(message: "", error: error)))
                    }
                    break
                case .failure(let error):
                    completion(.failure(.internalError(message: "", error: error)))
                    break
            }
        }
    }
}
