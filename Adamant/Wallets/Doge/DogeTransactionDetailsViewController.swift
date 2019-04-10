//
//  DogeTransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka

class DogeTransactionDetailsViewController: TransactionDetailsViewControllerBase {
    // MARK: - Dependencies
    
    weak var service: DogeWalletService?
    
    // MARK: - Properties
    
    private var cachedBlockInfo: (hash: String, height: String)? = nil
    
    private let autoupdateInterval: TimeInterval = 5.0
    weak var timer: Timer?
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: UIControl.Event.valueChanged)
        return control
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        currencySymbol = DogeWalletService.currencySymbol
        
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
        
        return URL(string: "\(AdamantResources.dogeExplorerAddress)\(id)")
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
    
    func updateTransaction(completion: ((RichError?) -> Void)? = nil) {
        guard let service = service, let address = service.wallet?.address, let id = transaction?.txId else {
            completion?(nil)
            return
        }

        service.getTransaction(by: id) { [weak self] result in
            switch result {
            case .success(let trs):
                if let blockInfo = self?.cachedBlockInfo, blockInfo.hash == trs.blockHash {
                    self?.transaction = trs.asDogeTransaction(for: address, blockId: blockInfo.height)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.tableView.reloadData()
                    }
                    
                    completion?(nil)
                } else if let blockHash = trs.blockHash {
                    service.getBlockId(by: blockHash) { result in
                        let blockInfo: (hash: String, height: String)?
                        switch result {
                        case .success(let height):
                            blockInfo = (hash: blockHash, height: height)
                            
                        case .failure:
                            blockInfo = nil
                        }
                        
                        self?.transaction = trs.asDogeTransaction(for: address, blockId: blockInfo?.height)
                        self?.cachedBlockInfo = blockInfo
                        
                        DispatchQueue.main.async { [weak self] in
                            self?.tableView.reloadData()
                        }
                        
                        completion?(nil)
                    }
                } else {
                    self?.transaction = trs.asDogeTransaction(for: address)
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.tableView.reloadData()
                    }
                    
                    completion?(nil)
                }
                
            case .failure(let error):
                completion?(error)
            }
        }
    }
}
