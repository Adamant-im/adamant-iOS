//
//  DogeTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import ProcedureKit

class DogeTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var walletService: DogeWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [DogeTransaction] = []
    
    private let limit = 200 // Limit autoload, as some wallets can have thousands of transactions.
    private(set) var loadedTo: Int = 0
    private let procedureQueue = ProcedureQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = DogeWalletService.currencySymbol
        
        refreshControl.beginRefreshing()
        handleRefresh(refreshControl)
    }
    
    deinit {
        procedureQueue.cancelAllOperations()
    }
    
    @MainActor
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.emptyLabel.isHidden = true
        procedureQueue.cancelAllOperations()
        
        loadedTo = 0
        refreshTask = Task {
            do {
                let tuple = try await walletService.getTransactions(from: loadedTo)
                transactions = tuple.transactions
                loadedTo = tuple.transactions.count
                emptyLabel.isHidden = transactions.count > 0
                refreshControl.endRefreshing()
                tableView.reloadData()
                
                // Update tableView, then call loadMore()
                if tuple.hasMore {
                    loadMoreTransactions(from: tuple.transactions.count)
                }
            } catch {
                transactions.removeAll()
                dialogService.showRichError(error: error)
                
                emptyLabel.isHidden = transactions.count > 0
                refreshControl.endRefreshing()
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    @MainActor func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Doge.transactionDetails) as? DogeTransactionDetailsViewController else {
            fatalError("Failed to get DogeTransactionDetailsViewController")
        }
        
        // Hold reference
        guard let sender = walletService.wallet?.address else {
            return
        }
        
        controller.service = self.walletService
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        let txId = transactions[indexPath.row].txId
        
        detailTransactionTask = Task {
            do {
                let dogeTransaction = try await walletService.getTransaction(by: txId)
                let transaction = dogeTransaction.asBtcTransaction(DogeTransaction.self, for: sender)
                
                // Sender name
                if transaction.senderAddress == sender {
                    controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
                }
                
                if transaction.recipientAddress == sender {
                    controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                }
                
                // Block Id
                guard let blockHash = dogeTransaction.blockHash else {
                    controller.transaction = transaction
                    navigationController?.pushViewController(controller, animated: true)
                    tableView.deselectRow(at: indexPath, animated: true)
                    dialogService.dismissProgress()
                    return
                }
                
                do {
                    let id = try await walletService.getBlockId(by: blockHash)
                    controller.transaction = dogeTransaction.asBtcTransaction(DogeTransaction.self, for: sender, blockId: id)
                } catch {
                    controller.transaction = transaction
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
                dialogService.dismissProgress()
                navigationController?.pushViewController(controller, animated: true)
            } catch {
                tableView.deselectRow(at: indexPath, animated: true)
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: DogeTransaction) {
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
                      amount: transaction.amountValue ?? 0,
                      date: transaction.dateValue)
    }
    
    // MARK: - Load more
    private func loadMoreTransactions(from: Int) {
        let procedure = LoadMoreDogeTransactionsProcedure(service: walletService, from: from)
        
        procedure.addDidFinishBlockObserver { [weak self] (procedure, _) in
            guard let vc = self, let result = procedure.result else {
                return
            }
            
            let total = vc.loadedTo + result.transactions.count
            
            var indexPaths = [IndexPath]()
            for index in from..<total {
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            
            DispatchQueue.main.async {
                vc.loadedTo = total
                vc.transactions.append(contentsOf: result.transactions)
                vc.tableView.insertRows(at: indexPaths, with: .fade)
                
                // Update everything, and then call loadMore()
                if result.hasMore && total < vc.limit {
                    vc.loadMoreTransactions(from: total)
                }
            }
        }
        
        procedureQueue.addOperation(procedure)
    }
}

private class LoadMoreDogeTransactionsProcedure: Procedure {
    let from: Int
    let service: DogeWalletService
    
    private(set) var result: (transactions: [DogeTransaction], hasMore: Bool)?
    
    init(service: DogeWalletService, from: Int) {
        self.from = from
        self.service = service
        
        super.init()
        log.severity = .warning
    }
    
    override func execute() {
        Task {
            do {
                let result = try await service.getTransactions(from: from)
                self.result = result
                self.finish()
            } catch {
                self.result = nil
                self.finish(with: error)
            }
        }
    }
}
