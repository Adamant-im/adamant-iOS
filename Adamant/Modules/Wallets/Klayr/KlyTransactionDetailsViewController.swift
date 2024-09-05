//
//  KlyTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit

final class KlyTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: KlyWalletService? {
        walletService?.core as? KlyWalletService
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
        currencySymbol = KlyWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if service != nil {
            tableView.refreshControl = refreshControl
        }
        
        refresh(silent: true)
        
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
        
        return URL(string: "\(KlyWalletService.explorerTx)\(id)")
    }
    
    @MainActor
    @objc func refresh(silent: Bool = false) {
        refreshTask = Task {
            guard let id = transaction?.txId,
                  let service = service
            else {
                refreshControl.endRefreshing()
                return
            }
            
            do {
                var trs = try await service.getTransaction(by: id)
                let result = try await service.getCurrentFee()
                
                let lastHeight = result.lastHeight
                trs.updateConfirmations(value: lastHeight)
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
