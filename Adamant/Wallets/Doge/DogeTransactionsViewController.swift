//
//  DogeTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

class DogeTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var walletService: DogeWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [DogeTransaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        currencySymbol = DogeWalletService.currencySymbol
        
        handleRefresh(self.refreshControl)
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        transactions.removeAll()
        
        walletService.getTransactions(from: 0) { [weak self] result in
            switch result {
            case .success(let tuple):
                self?.transactions = tuple.transactions
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    self?.refreshControl.endRefreshing()
                }
                
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Doge.transactionDetails) as? DogeTransactionDetailsViewController else {
            fatalError("Failed to get DogeTransactionDetailsViewController")
        }
        
        controller.service = self.walletService
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        let txId = transactions[indexPath.row].txId
        
        walletService.getTransaction(by: txId) { result in
            DispatchQueue.main.async {
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.dialogService.dismissProgress()
            }
            
            switch result {
            case .success(let dogeTransaction):
                controller.transaction = dogeTransaction
                
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(controller, animated: true)
                }
                
            case .failure(let error):
                self.dialogService.showRichError(error: error)
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
        
        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId,
                      partnerName: nil,
                      amount: transaction.amountValue,
                      date: transaction.dateValue)
    }
}
