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
    private var offset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = DogeWalletService.currencySymbol
        
        refreshControl.beginRefreshing()
        handleRefresh()
    }
    
    override func handleRefresh() {
        offset = 0
        transactions.removeAll()
        tableView.reloadData()
        loadData(false)
    }
    
    override func loadData(_ silent: Bool) {
        isBusy = true
        
        Task {
            do {
                let tuple = try await walletService.getTransactions(from: offset)
                transactions.append(contentsOf: tuple.transactions)
                offset += tuple.transactions.count
                isNeedToLoadMoore = tuple.hasMore
            } catch {
                isNeedToLoadMoore = false

                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = transactions.count > 0
            stopBottomIndicator()
            refreshControl.endRefreshing()
            tableView.reloadData()
        }.stored(in: taskManager)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        
        Task { @MainActor in
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
        }.stored(in: taskManager)
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
