//
//  EthTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import Combine

final class EthTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: EthWalletService? {
        walletService?.core as? EthWalletService
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = EthWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if service != nil {
            tableView.refreshControl = refreshControl
        }
        
        startUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(EthWalletService.explorerAddress)\(id)")
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
                let trs = try await service.getTransaction(by: id)
                transaction = trs
                updateIncosinstentRowIfNeeded()
                tableView.reloadData()
                refreshControl.endRefreshing()
            } catch {
                updateTransactionStatus()
                if !silent {
                    dialogService.showRichError(error: error)
                }
                refreshControl.endRefreshing()
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
