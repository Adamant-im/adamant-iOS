//
//  ERC20TransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import CommonKit
import Combine

@MainActor
final class ERC20TransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: ERC20WalletService? {
        walletService?.core as? ERC20WalletService
    }
    
    // MARK: - Properties
    
    private let autoupdateInterval: TimeInterval = 5.0
    private var timerSubscription: AnyCancellable?
    override var feeFormatter: NumberFormatter {
        return AdamantBalanceFormat.currencyFormatter(for: .full, currencySymbol: EthWalletService.currencySymbol)
    }
    
    override var feeCurrencySymbol: String? {
        EthWalletService.currencySymbol
    }
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.tintColor = .adamant.primary
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = service?.tokenSymbol
        
        super.viewDidLoad()
        
        if service != nil {
            tableView.refreshControl = refreshControl
        }
        
        startUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.txId
        
        return URL(string: "\(EthWalletService.explorerTx)\(id)")
    }
    
    @MainActor
    @objc func refresh(silent: Bool = false) {
        refreshTask = Task {
            guard let id = transaction?.txId, let service = service else {
                refreshControl.endRefreshing()
                return
            }
            
            do {
                let trs = try await service.getTransaction(by: id, waitsForConnectivity: false)
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
        refresh(silent: true)
        timerSubscription = Timer
            .publish(every: autoupdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh(silent: true)
            }
    }
}
