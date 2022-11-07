//
//  BtcTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 30/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import BitcoinKit

class BtcTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var btcWalletService: BtcWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [BtcTransaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        currencySymbol = BtcWalletService.currencySymbol
        
        handleRefresh(self.refreshControl)
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.btcWalletService.getTransactions { (result) in
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
                self.emptyLabel.isHidden = self.transactions.count > 0
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Bitcoin.transactionDetails) as? BtcTransactionDetailsViewController else {
            return
        }

        controller.transaction = transaction
        controller.service = btcWalletService

        if let address = btcWalletService.wallet?.address {
            if transaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
                controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
            }
            if transaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
                controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
            }
        }

        navigationController?.pushViewController(controller, animated: true)
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: BtcTransaction) {
        let outgoing = transaction.isOutgoing
        let partnerId = outgoing ? transaction.recipientAddress : transaction.senderAddress
        
        let partnerName: String?
        if let address = btcWalletService.wallet?.address, partnerId == address {
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
