//
//  DogeWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import Swinject
import BitcoinKit
import BitcoinKit.Private

class DogeWalletService: WalletService {
    var wallet: WalletAccount? { return dogeWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.wallet) as? DogeWalletViewController else {
            fatalError("Can't get DogeWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "doge_transaction"
    let cellIdentifierSent = "dogeTransferSent"
    let cellIdentifierReceived = "dogeTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    static var currencySymbol = "DOGE"
    static var currencyLogo = #imageLiteral(resourceName: "wallet_doge")
    
    static let multiplier = 1e8
    static let chunkSize = 20
    
    private (set) var transactionFee: Decimal = 1 // 1 DOGE per transaction
    
    static let kvsAddress = "doge:address"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.dogeWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.dogeWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.dogeWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.dogeWallet.feeUpdated")
    
    // MARK: - Delayed KVS save
    private var balanceObserver: NSObjectProtocol? = nil
    
    // MARK: - Properties
    private (set) var dogeWallet: DogeWallet? = nil
    
    private (set) var enabled = true
    
    public var network: Network
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.dogeWalletService", qos: .utility, attributes: [.concurrent])
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    // MARK: - State
    private (set) var state: WalletServiceState = .notInitiated
    
    private func setState(_ newState: WalletServiceState, silent: Bool = false) {
        guard newState != state else {
            return
        }
        
        state = newState
        
        if !silent {
            NotificationCenter.default.post(name: serviceStateChanged,
                                            object: self,
                                            userInfo: [AdamantUserInfoKey.WalletService.walletState: state])
        }
    }
    
    init(mainnet: Bool) {
        self.network = mainnet ? DogeMainnet() : DogeTestnet()
        
        self.setState(.notInitiated)
    }
    
    func update() {
        // Tooo
    }
    
    func validate(address: String) -> AddressValidationResult {
        // Todo
        return .valid
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        // Todo
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension DogeWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        stateSemaphore.wait()
        setState(.initiationFailed(reason: reason))
        dogeWallet = nil
        stateSemaphore.signal()
    }
    
    func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
        guard let adamant = accountService.account else {
            completion(.failure(error: .notLogged))
            return
        }
        
        stateSemaphore.wait()
        
        setState(.notInitiated)
        
        if enabled {
            enabled = false
            NotificationCenter.default.post(name: serviceEnabledChanged, object: self)
        }
        
        defaultDispatchQueue.async { [unowned self] in
            let privateKeyData = passphrase.data(using: .utf8)!.sha256()
            let privateKey = PrivateKey(data: privateKeyData, network: self.network, isPublicKeyCompressed: true)
            
            let eWallet = DogeWallet(privateKey: privateKey)
            self.dogeWallet = eWallet
            
            if !self.enabled {
                self.enabled = true
                NotificationCenter.default.post(name: self.serviceEnabledChanged, object: self)
            }
            
            self.stateSemaphore.signal()
            
            // MARK: 4. Save address into KVS
            self.getWalletAddress(byAdamantAddress: adamant.address) { [weak self] result in
                guard let service = self else {
                    return
                }
                
                switch result {
                case .success(let address):
                    // DOGE already saved
                    if address != eWallet.address {
                        service.save(dogeAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
                        }
                    }
                    
                    service.initialBalanceCheck = true
                    service.setState(.upToDate, silent: true)
                    service.update()
                    
                    completion(.success(result: eWallet))
                    
                case .failure(let error):
                    switch error {
                    case .walletNotInitiated:
                        // Show '0' without waiting for balance update
                        if let wallet = service.dogeWallet {
                            NotificationCenter.default.post(name: service.walletUpdatedNotification, object: service, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                        }
                        
                        service.save(dogeAddress: eWallet.address) { result in
                            service.kvsSaveCompletionRecursion(dogeAddress: eWallet.address, result: result)
                        }
                        service.setState(.upToDate)
                        completion(.success(result: eWallet))
                        
                    default:
                        service.setState(.upToDate)
                        completion(.failure(error: error))
                    }
                }
            }
        }
    }
}

// MARK: - KVS
extension DogeWalletService {
    /// - Parameters:
    ///   - dogeAddress: DOGE address to save into KVS
    ///   - adamantAddress: Owner of Lisk address
    ///   - completion: success
    private func save(dogeAddress: String, completion: @escaping (WalletServiceSimpleResult) -> Void) {
        guard let adamant = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(error: .notLogged))
            return
        }
        
        guard adamant.balance >= AdamantApiService.KvsFee else {
            completion(.failure(error: .notEnoughMoney))
            return
        }
        
        apiService.store(key: DogeWalletService.kvsAddress, value: dogeAddress, type: .keyValue, sender: adamant.address, keypair: keypair) { result in
            switch result {
            case .success:
                completion(.success)
                
            case .failure(let error):
                completion(.failure(error: .apiError(error)))
            }
        }
    }
    
    /// New accounts doesn't have enought money to save KVS. We need to wait for balance update, and then - retry save
    private func kvsSaveCompletionRecursion(dogeAddress: String, result: WalletServiceSimpleResult) {
        if let observer = balanceObserver {
            NotificationCenter.default.removeObserver(observer)
            balanceObserver = nil
        }
        
        switch result {
        case .success:
            break
            
        case .failure(let error):
            switch error {
            case .notEnoughMoney:  // Possibly new account, we need to wait for dropship
                // Register observer
                let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: nil) { [weak self] _ in
                    guard let balance = self?.accountService.account?.balance, balance > AdamantApiService.KvsFee else {
                        return
                    }
                    
                    self?.save(dogeAddress: dogeAddress) { result in
                        self?.kvsSaveCompletionRecursion(dogeAddress: dogeAddress, result: result)
                    }
                }
                
                // Save referense to unregister it later
                balanceObserver = observer
                
            default:
                dialogService.showRichError(error: error)
            }
        }
    }
}

class DogeMainnet: Network {
    override var name: String {
        return "livenet"
    }
    
    override var alias: String {
        return "mainnet"
    }
    
    override var scheme: String {
        return "dogecoin"
    }
    
    override var magic: UInt32 {
        return 0xc0c0c0c0
    }
    
    override var pubkeyhash: UInt8 {
        return 0x1e
    }
    
    override var privatekey: UInt8 {
        return 0x9e
    }
    
    override var scripthash: UInt8 {
        return 0x16
    }
    
    override var xpubkey: UInt32 {
        return 0x02facafd
    }
    
    override var xprivkey: UInt32 {
        return 0x02fac398
    }
    
    override var port: UInt32 {
        return 22556
    }
    
    override var dnsSeeds: [String] {
        return [
            "seed.dogecoin.com",
            "seed.multidoge.org",
            "seed2.multidoge.org",
            "seed.doger.dogecoin.com"
        ]
    }
    
    // todo hashGenesisBlock = "1a91e3dace36e2be3bf030a65679fe821aa1d6ef92e7c9902eb318182c355691"
}

class DogeTestnet: Network {
    override var name: String {
        return "livenet"
    }
    
    override var alias: String {
        return "mainnet"
    }
    
    override var scheme: String {
        return "dogecoin"
    }
    
    override var magic: UInt32 {
        return 0xc0c0c0c0
    }
    
    override var pubkeyhash: UInt8 {
        return 0x71
    }
    
    override var privatekey: UInt8 {
        return 0xf1
    }
    
    override var scripthash: UInt8 {
        return 0xc4
    }
    
    override var xpubkey: UInt32 {
        return 0x02facafd
    }
    
    override var xprivkey: UInt32 {
        return 0x02fac398
    }
    
    override var port: UInt32 {
        return 22556
    }
    
    override var dnsSeeds: [String] {
        return [
            //            "seed.dogecoin.com",
            //            "seed.multidoge.org",
            //            "seed2.multidoge.org",
            //            "seed.doger.dogecoin.com"
        ]
    }
    
    // todo hashGenesisBlock = ""
}
