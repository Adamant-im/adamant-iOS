//
//  BtcWalletService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 14/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject
import BitcoinKit
import BitcoinKit.Private

class BtcWalletService: WalletService {
    var wallet: WalletAccount? { return btcWallet }
    
    var walletViewController: WalletViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Bitcoin.wallet) as? BtcWalletViewController else {
            fatalError("Can't get BtcWalletViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: RichMessageProvider properties
    static let richMessageType = "btc_transaction"
    let cellIdentifierSent = "btcTransferSent"
    let cellIdentifierReceived = "btcTransferReceived"
    let cellSource: CellSource? = CellSource.nib(nib: UINib(nibName: "TransferCollectionViewCell", bundle: nil))
    
    // MARK: - Dependencies
    var apiService: ApiService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Constants
    static var currencySymbol = "BTC"
    static var currencyLogo = #imageLiteral(resourceName: "wallet_lsk")
    
    static let defaultFee: Int64 = 500
    
    static let kvsAddress = "btc:address"
    private (set) var transactionFee: Decimal = Decimal(BtcWalletService.defaultFee) / Decimal(100000000)
    
    static let walletPath = "m/44'/1'/3'/1"
    
    // MARK: - Notifications
    let walletUpdatedNotification = Notification.Name("adamant.brchWallet.walletUpdated")
    let serviceEnabledChanged = Notification.Name("adamant.btcWallet.enabledChanged")
    let serviceStateChanged = Notification.Name("adamant.btcWallet.stateChanged")
    let transactionFeeUpdated = Notification.Name("adamant.btcWallet.feeUpdated")
    
    // MARK: - Properties
    private var btcWallet: BtcWallet? = nil
    
    private (set) var enabled = true
    
    private var network = AdmBTCTestnet()
    
    private var initialBalanceCheck = false
    
    let defaultDispatchQueue = DispatchQueue(label: "im.adamant.btcWalletService", qos: .utility, attributes: [.concurrent])
    let stateSemaphore = DispatchSemaphore(value: 1)
    
    var peerGroup: PeerGroup?
    var blockStore: SQLiteBlockStore?
    
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
    
    init() {
        
    }
    
    deinit {
        self.stopSync()
    }
    
    func update() {
        guard let wallet = btcWallet else {
            return
        }
        
        defer { stateSemaphore.signal() }
        stateSemaphore.wait()
        
        switch state {
        case .notInitiated, .updating, .initiationFailed(_):
            return
            
        case .upToDate:
            break
        }
        
        setState(.updating)
        
        getBalance { [weak self] result in
            if let stateSemaphore = self?.stateSemaphore {
                defer {
                    stateSemaphore.signal()
                }
                stateSemaphore.wait()
            }
            
            switch result {
            case .success(let balance):
                let notification: Notification.Name?
                
                if wallet.balance != balance {
                    wallet.balance = balance
                    notification = self?.walletUpdatedNotification
                    self?.initialBalanceCheck = false
                } else if let initialBalanceCheck = self?.initialBalanceCheck, initialBalanceCheck {
                    self?.initialBalanceCheck = false
                    notification = self?.walletUpdatedNotification
                } else {
                    notification = nil
                }
                
                if let notification = notification {
                    NotificationCenter.default.post(name: notification, object: self, userInfo: [AdamantUserInfoKey.WalletService.wallet: wallet])
                }
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
            }
            
            self?.setState(.upToDate)
        }
    }
    
    func validate(address: String) -> AddressValidationResult {
        return .valid
    }
    
    func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void) {
        
    }
    
    func startSync() {
        print("start sync")
        let blockStore = SQLiteBlockStore(network: self.network)
        let blockChain = BlockChain(network: self.network, blockStore: blockStore)
        self.peerGroup = PeerGroup(blockChain: blockChain)
        self.peerGroup?.delegate = self
        
        self.blockStore = blockStore
        
        if let wallet = self.btcWallet, let address = try? wallet.keystore.receiveAddress() {
            if let publicKey = address.publicKey {
                self.peerGroup?.addFilter(publicKey)
            }
            self.peerGroup?.addFilter(address.data)
        }
        
        self.peerGroup?.start()
    }
    
    func stopSync() {
        if let peerGroup = peerGroup {
            print("stop sync")
            peerGroup.stop()
        }
    }
}

// MARK: - WalletInitiatedWithPassphrase
extension BtcWalletService: InitiatedWithPassphraseService {
    func setInitiationFailed(reason: String) {
        
    }
    
    func initWallet(withPassphrase passphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void) {
        
        defaultDispatchQueue.async { [unowned self] in
            let mnemonic = passphrase.components(separatedBy: " ")
            let seed = BitcoinKit.Mnemonic.seed(mnemonic: mnemonic)
            let keystore = HDWallet(seed: seed, network: self.network)
            let address = try! keystore.receiveAddress()
            
            let eWallet = BtcWallet(address: address.base58, keystore: keystore)
            self.btcWallet = eWallet

            self.startSync()
            self.setState(.upToDate)
            completion(.success(result: eWallet))
        }
    }
}

// MARK: - Dependencies
extension BtcWalletService: SwinjectDependentService {
    func injectDependencies(from container: Container) {
        accountService = container.resolve(AccountService.self)
        apiService = container.resolve(ApiService.self)
        dialogService = container.resolve(DialogService.self)
        router = container.resolve(Router.self)
    }
}

// MARK: - Balances & addresses
extension BtcWalletService {
    func getBalance(_ completion: @escaping (WalletServiceResult<Decimal>) -> Void) {
        if let address = try! self.btcWallet?.keystore.receiveAddress(), let blockChain = self.peerGroup?.blockChain {
            let balance: Int64 = try! blockChain.calculateBalance(address: address)
            
            DispatchQueue.main.async {
                let decimal = Decimal(balance)
                completion(.success(result: (decimal / Decimal(100000000))))
            }
        } else {
            completion(.failure(error: .internalError(message: "BTC Wallet: not found", error: nil)))
        }
    }
}

// MARK: - Transactions
extension BtcWalletService {
    func getTransactions(_ completion: @escaping (ApiServiceResult<[Payment]>) -> Void) {
        if let address = try! self.btcWallet?.keystore.receiveAddress(), let blockStore = self.blockStore {
            defaultDispatchQueue.async {
                if let transactions = try? blockStore.transactions(address: address) {
                     completion(.success(transactions))
                } else {
                    completion(.success([Payment]()))
                }
            }
        } else {
            completion(.failure(.internalError(message: "BTC Wallet: not found", error: nil)))
        }
    }
    
    func getTransaction(by hash: String, completion: @escaping (ApiServiceResult<Payment>) -> Void) {
        defaultDispatchQueue.async {
            do {
                if let transaction = try self.blockStore?.transaction(with: hash) {
                    completion(.success(transaction))
                }
            } catch (let error) {
                completion(ApiServiceResult.failure(ApiServiceError.networkError(error: AdamantError(message: "Problem with getting BTC transaction", error: error))))
            }
        }
    }
}

extension BtcWalletService: WalletServiceWithTransfers {
    func transferListViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Bitcoin.transactionsList) as? BtcTransactionsViewController else {
            fatalError("Can't get BtcTransactionsViewController")
        }
        
        vc.btcWalletService = self
        return vc
    }
}


// BTC Sync
extension BtcWalletService: PeerGroupDelegate {
    func peerGroupDidStop(_ peerGroup: PeerGroup) {
        peerGroup.delegate = nil
        self.peerGroup = nil
    }

    func peerGroupDidReceiveTransaction(_ peerGroup: PeerGroup) {
        
    }
}

class AdmBTCTestnet: Network {
    public override var name: String {
        return "testnet"
    }
    public override var alias: String {
        return "regtest"
    }
    override public var pubkeyhash: UInt8 {
        return 0x6f
    }
    override public var privatekey: UInt8 {
        return 0xef
    }
    override public var scripthash: UInt8 {
        return 0xc4
    }
    override public var xpubkey: UInt32 {
        return 0x043587cf
    }
    override public var xprivkey: UInt32 {
        return 0x04358394
    }
    public override var port: UInt32 {
        return 18_333
    }
    override public var checkpoints: [Checkpoint] {
        return [
//            Checkpoint(height: 0, hash: Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed()), timestamp: 1_376_543_922, target: 0x1d00ffff),
            Checkpoint(height: 1450248, hash: Data(Data(hex: "000000000000d19bf1c7fdcc2f2d9a917fd837628ce09ed9439771a6d8391210")!.reversed()), timestamp: 1546234270, target: 0x1d00ffff)
        ]
    }
    override public var genesisBlock: Data {
        return Data(Data(hex: "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943")!.reversed())
    }
    
    override var scheme: String {
        return "bitcoin"
    }

    override public var magic: UInt32 {
        return 0x0b110907
    }
    override var dnsSeeds: [String] {
        return [
//            "testnet-seed.bitcoin.jonasschnelli.ch", // Jonas Schnelli
            "testnet-seed.bluematt.me",              // Matt Corallo
            "testnet-seed.bitcoin.petertodd.org",    // Peter Todd
            "testnet-seed.bitcoin.schildbach.de",    // Andreas Schildbach
            "bitcoin-testnet.bloqseeds.net"         // Bloq
        ]
    }
}
