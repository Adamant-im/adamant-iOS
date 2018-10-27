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
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        currencySymbol = EthWalletService.currencySymbol
        
        super.viewDidLoad()
        
        if service != nil {
            tableView.refreshControl = refreshControl
        }
    }
    
    override func explorerUrl(for transaction: TransactionDetails) -> URL? {
        guard let id = transaction.id else {
            return nil
        }
        
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
}
