//
//  DashTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import ProcedureKit

class DashTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var walletService: DashWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [DashTransaction] = []
    
    private let limit = 200 // Limit autoload, as some wallets can have thousands of transactions.
    private(set) var loadedTo: Int = 0
    private let procedureQueue = ProcedureQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = DashWalletService.currencySymbol
        
        refreshControl.beginRefreshing()
        handleRefresh(refreshControl)
    }
    
    deinit {
        procedureQueue.cancelAllOperations()
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.emptyLabel.isHidden = true
        procedureQueue.cancelAllOperations()
        
        loadedTo = 0
        walletService.getTransactions(from: loadedTo) { [weak self] result in
            guard let vc = self else {
                refreshControl.endRefreshing()
                return
            }
            
            switch result {
            case .success(let tuple):
                vc.transactions = tuple.transactions
                vc.loadedTo = tuple.transactions.count
                
                DispatchQueue.main.async {
                    vc.emptyLabel.isHidden = vc.transactions.count > 0
                    vc.tableView.reloadData()
                    refreshControl.endRefreshing()
                    
                    // Update tableView, then call loadMore()
                    if tuple.hasMore {
                        vc.loadMoreTransactions(from: tuple.transactions.count)
                    }
                }
                
            case .failure(let error):
                vc.transactions.removeAll()
                vc.dialogService.showRichError(error: error)
                
                DispatchQueue.main.async {
                    vc.emptyLabel.isHidden = vc.transactions.count > 0
                    vc.tableView.reloadData()
                    refreshControl.endRefreshing()
                }
            }
        }
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            fatalError("Failed to getDashTransactionDetailsViewController")
        }

        // Hold reference
        guard let sender = walletService.wallet?.address else {
            return
        }

        controller.service = self.walletService
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        let txId = transactions[indexPath.row].txId

        walletService.getTransaction(by: txId) { [weak self] result in
            guard let vc = self else {
                return
            }

            switch result {
            case .success(let dashTransaction):
                let transaction = dashTransaction.asBtcTransaction(DashTransaction.self, for: sender)

                // Sender name
                if transaction.senderAddress == sender {
                    controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
                }

                if transaction.recipientAddress == sender {
                    controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                }

                // Block Id
                guard let blockHash = dashTransaction.blockHash else {
                    controller.transaction = transaction
                    DispatchQueue.main.async {
                        vc.navigationController?.pushViewController(controller, animated: true)
                        vc.tableView.deselectRow(at: indexPath, animated: true)
                        vc.dialogService.dismissProgress()
                    }
                    break
                }

                vc.walletService.getBlockId(by: blockHash) { result in
                    switch result {
                    case .success(let id):
                        controller.transaction = dashTransaction.asBtcTransaction(DashTransaction.self, for: sender, blockId: id)

                    case .failure:
                        controller.transaction = transaction
                    }

                    DispatchQueue.main.async {
                        vc.tableView.deselectRow(at: indexPath, animated: true)
                        vc.dialogService.dismissProgress()
                        vc.navigationController?.pushViewController(controller, animated: true)
                    }
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    vc.tableView.deselectRow(at: indexPath, animated: true)
                    vc.dialogService.dismissProgress()
                    vc.dialogService.showRichError(error: error)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as? TransactionTableViewCell else {
            // TODO: Display & Log error
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        
        configureCell(cell, for: transaction)
        return cell
    }
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: BaseBtcTransaction) {
        let outgoing = transaction.isOutgoing
        let partnerId = outgoing ? transaction.recipientAddress : transaction.senderAddress

        let partnerName: String?
        if let address = walletService.wallet?.address, partnerId == address {
            partnerName = String.adamantLocalized.transactionDetails.yourAddress
        } else {
            partnerName = nil
        }

        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId,
                      partnerName: partnerName,
                      amount: transaction.amountValue,
                      date: transaction.dateValue)
    }
    
    // MARK: - Load more
    private func loadMoreTransactions(from: Int) {
        let procedure = LoadMoreDashTransactionsProcedure(service: walletService, from: from)

        procedure.addDidFinishBlockObserver { [weak self] (procedure, error) in
            guard let vc = self, let result = procedure.result else {
                return
            }
            
            let total = vc.loadedTo + result.transactions.count
            
            guard from < total else { return }
            
            var indexPaths = [IndexPath]()
            for index in from..<total {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            
            DispatchQueue.main.async {
                vc.loadedTo = total
                vc.transactions.append(contentsOf: result.transactions)
                vc.transactions.sort(by: { (t1, t2) -> Bool in
                    return t1.dateValue ?? Date() > t2.dateValue ?? Date()
                })
                
                for transaction in result.transactions {
                    if let index = vc.transactions.firstIndex(where: { (tr) -> Bool in
                        return tr.txId == transaction.txId
                    }) {
                        let indexPath = IndexPath(row: index, section: 0)
                        vc.tableView.insertRows(at: [indexPath], with: .fade)
                    }
                }
                
                // Update everything, and then call loadMore()
                if result.hasMore && total < vc.limit {
                    vc.loadMoreTransactions(from: total)
                }
            }
        }
        
        procedureQueue.addOperation(procedure)
    }
}


private class LoadMoreDashTransactionsProcedure: Procedure {
    let from: Int
    let service: DashWalletService
    
    private(set) var result: (transactions: [DashTransaction], hasMore: Bool)? = nil
    
    init(service: DashWalletService, from: Int) {
        self.from = from
        self.service = service
        
        super.init()
        log.severity = .warning
    }
    
    override func execute() {
        service.getTransactions(from: from) { result in
            switch result {
            case .success(let result):
                self.result = result
                self.finish()
                
            case .failure(let error):
                self.result = nil
                self.finish(with: error)
            }
        }
    }
}
