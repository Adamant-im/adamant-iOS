//
//  ETHTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class ETHTransactionsViewController: TransactionsViewController {
    
    // MARK: - Dependencies
//    var ethApiService: EthApiService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [EthTransaction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        handleRefresh(self.refreshControl)
    }
    
	/*
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.ethApiService.getTransactions({ (result) in
            switch result {
            case .success(let transactions):
                self.transactions = transactions
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                break
            case .failure(let error):
                if case .internalError(let message, _ ) = error {
                    let localizedErrorMessage = NSLocalizedString(message, comment: "TransactionList: 'Transactions not found' message.")
                    self.dialogService.showWarning(withMessage: localizedErrorMessage)
                } else {
                    self.dialogService.showError(withMessage: String.adamantLocalized.transactionList.notFound, error: error)
                }
                break
            }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    override func currentAddress() -> String {
        guard let address = ethApiService.account?.address else {
            return ""
        }
        return address
    }
*/
}

// MARK: - UITableView
extension ETHTransactionsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Transactions.ethTransactionDetails) as? BaseTransactionDetailsViewController else {
            return
        }

        controller.transaction = transaction
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransactionTableViewCell else {
                // TODO: Display & Log error
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        
        configureCell(cell, for: transaction)
        return cell
    }
}
