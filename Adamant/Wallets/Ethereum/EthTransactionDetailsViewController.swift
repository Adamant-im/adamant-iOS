//
//  EthTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.10.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class EthTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: EthWalletService?
    
    // MARK: - Properties
    
    private let autoupdateInterval: TimeInterval = 5.0
    weak var timer: Timer?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
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
    
    deinit {
        stopUpdate()
    }
    
    // MARK: - Overrides
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        let id = transaction.id
        
        return URL(string: "\(AdamantResources.ethereumExplorerAddress)\(id)")
    }
    
    @objc func refresh() {
        guard let id = transaction?.id, let service = service else {
            refreshControl.endRefreshing()
            return
        }
        
        service.getTransaction(by: id) { [weak self] result in
            switch result {
            case .success(let trs):
                self?.transaction = trs
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
                
            case .failure(let error):
                self?.dialogService.showRichError(error: error)
                
                DispatchQueue.main.async {
                    self?.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    // MARK: - Autoupdate
    
    func startUpdate() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
            guard let id = self?.transaction?.id, let service = self?.service else {
                return
            }
            
            service.getTransaction(by: id) { result in
                switch result {
                case .success(let trs):
                    self?.transaction = trs
                    
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                    
                case .failure:
                    break
                }
            }
        }
    }
    
    func stopUpdate() {
        timer?.invalidate()
    }
}
