//
//  DashTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class DashTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: DashWalletService?
    
    // MARK: - Properties
    
    private var cachedBlockInfo: (hash: String, height: String)?
    
    private let autoupdateInterval: TimeInterval = 5.0
    weak var timer: Timer?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .adamant.primary
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = DashWalletService.currencySymbol
        
        super.viewDidLoad()
        if service != nil { tableView.refreshControl = refreshControl }
        
        updateTransaction()
        
        // MARK: Start update
        if transaction != nil {
            startUpdate()
        }
    }
    
    deinit {
        stopUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(DashWalletService.explorerAddress)\(id)")
    }
    
    @objc func refresh() {
        updateTransaction { [weak self] error in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                
                if let error = error {
                    self?.dialogService.showRichError(error: error)
                }
            }
        }
    }
    
    // MARK: Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            self?.updateTransaction() // Silent, without errors
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
    
    // MARK: Updating methods
    
    @MainActor
    func updateTransaction(completion: ((RichError?) -> Void)? = nil) {
        guard let service = service, let address = service.wallet?.address, let id = transaction?.txId else {
            completion?(nil)
            return
        }
        
        Task { [weak self] in
            do {
                let trs = try await service.getTransaction(by: id)
                if let blockInfo = self?.cachedBlockInfo, blockInfo.hash == trs.blockHash {
                    self?.transaction = trs.asBtcTransaction(DashTransaction.self, for: address, blockId: blockInfo.height)

                    self?.tableView.reloadData()

                    completion?(nil)
                } else if let blockHash = trs.blockHash {
                    let blockInfo: (hash: String, height: String)?
                    do {
                        let blockId = try await service.getBlockId(by: blockHash)
                        blockInfo = (hash: blockHash, height: blockId)
                    } catch {
                        blockInfo = nil
                    }
                    self?.transaction = trs.asBtcTransaction(DashTransaction.self, for: address, blockId: blockInfo?.height)
                    self?.cachedBlockInfo = blockInfo

                    self?.tableView.reloadData()

                    completion?(nil)
                    
                } else {
                    self?.transaction = trs.asBtcTransaction(DashTransaction.self, for: address)

                    self?.tableView.reloadData()

                    completion?(nil)
                }
            } catch let error as WalletServiceError {
                completion?(error)
            } catch {
                completion?(nil)
            }
        }
        
    }
}
