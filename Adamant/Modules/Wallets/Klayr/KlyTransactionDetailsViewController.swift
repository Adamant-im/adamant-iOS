//
//  KlyTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import Combine

final class KlyTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: KlyWalletService? {
        walletService?.core as? KlyWalletService
    }
    
    // MARK: - Properties
    
    private let autoupdateInterval: TimeInterval = 5.0
    private var timerSubscription: AnyCancellable?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .adamant.primary
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    override var showTxBlockchainComment: Bool {
        true
    }
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
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(KlyWalletService.explorerAddress)\(id)")
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
                updateTxDataRow()
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
        refresh(silent: true)
        timerSubscription = Timer
            .publish(every: autoupdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh(silent: true)
            }
    }
}
