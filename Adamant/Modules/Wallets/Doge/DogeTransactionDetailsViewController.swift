//
//  DogeTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import CommonKit
import Combine

final class DogeTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: DogeWalletService? {
        walletService?.core as? DogeWalletService
    }
    
    // MARK: - Properties
    
    private var cachedBlockInfo: (hash: String, height: String)?
    
    private let autoupdateInterval: TimeInterval = 5.0
    private var timerSubscription: AnyCancellable?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .adamant.primary
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = DogeWalletService.currencySymbol
        
        super.viewDidLoad()
        if service != nil { tableView.refreshControl = refreshControl }
        
        refresh(silent: true)
        
        // MARK: Start update
        if transaction != nil {
            startUpdate()
        }
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(DogeWalletService.explorerAddress)\(id)")
    }
    
    @MainActor
    @objc func refresh(silent: Bool = false) {
        refreshTask = Task {
            do {
                try await updateTransaction()
                refreshControl.endRefreshing()
            } catch {
                refreshControl.endRefreshing()
                updateTransactionStatus()
                
                guard !silent else { return }
                dialogService.showRichError(error: error)
            }
        }
    }
    
    // MARK: Autoupdate
    
    func startUpdate() {
        refresh(silent: true)
        timerSubscription = Timer
            .publish(every: autoupdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh(silent: true)
            }
    }
    
    // MARK: Updating methods
    
    @MainActor
    func updateTransaction() async throws {
        guard let service = service,
              let address = service.wallet?.address,
              let id = transaction?.txId
        else {
            return
        }

        let trs = try await service.getTransaction(by: id, waitsForConnectivity: false)
        
        if let blockInfo = cachedBlockInfo,
           blockInfo.hash == trs.blockHash {
            transaction = trs.asBtcTransaction(
                DogeTransaction.self,
                for: address,
                blockId: blockInfo.height
            )
            
            tableView.reloadData()
        } else if let blockHash = trs.blockHash {
            let blockInfo: (hash: String, height: String)?
            
            do {
                let height = try await service.getBlockId(by: blockHash)
                blockInfo = (hash: blockHash, height: height)
            } catch {
                blockInfo = nil
            }
            
            transaction = trs.asBtcTransaction(
                DogeTransaction.self,
                for: address,
                blockId: blockInfo?.height
            )
            
            cachedBlockInfo = blockInfo
            
            tableView.reloadData()
        } else {
            transaction = trs.asBtcTransaction(DogeTransaction.self, for: address)
            
            tableView.reloadData()
        }
        
        updateIncosinstentRowIfNeeded()
    }
}
