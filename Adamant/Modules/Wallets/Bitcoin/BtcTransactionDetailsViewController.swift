//
//  BtcTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 05/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import CommonKit

final class BtcTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: BtcWalletService? {
        walletService?.core as? BtcWalletService
    }
    
    // MARK: - Properties
    
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
        currencySymbol = BtcWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if service != nil {
            tableView.refreshControl = refreshControl
        }
        
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
        return URL(string: "\(BtcWalletService.explorerAddress)\(id)")
    }
    
    @MainActor
    @objc func refresh(silent: Bool = false) {
        refreshTask = Task {
            guard let id = transaction?.txId, let service = service else {
                refreshControl.endRefreshing()
                return
            }
            
            do {
                let trs = try await service.getTransaction(by: id)
                transaction = trs
                
                updateIncosinstentRowIfNeeded()
                tableView.reloadData()
                refreshControl.endRefreshing()
            } catch {
                refreshControl.endRefreshing()
                updateTransactionStatus()
                
                guard !silent else { return }
                dialogService.showRichError(error: error)
            }
        }
    }
    
    // MARK: - Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        refresh(silent: true)
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            self?.refresh(silent: true)
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
