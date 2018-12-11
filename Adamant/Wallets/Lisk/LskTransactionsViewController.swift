//
//  LskTransactionsViewController
//  Adamant
//
//  Created by Anton Boyarkin on 17/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Lisk
import web3swift
import BigInt

class LskTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var lskWalletService: LskWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [Transactions.TransactionModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.beginRefreshing()
        
        currencySymbol = LskWalletService.currencySymbol
        
        handleRefresh(self.refreshControl)
    }
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.lskWalletService.getTransactions({ (result) in
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
    
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? TransactionDetailsViewControllerBase else {
            return
        }
        
        controller.transaction = transaction
        
        if let address = lskWalletService.wallet?.address {
            if transaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
                controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
            } else if transaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: Transactions.TransactionModel) {
        let outgoing = isOutgoing(transaction)
        let partnerId = outgoing ? transaction.recipientId : transaction.senderId
        
        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId ?? "",
                      partnerName: nil,
                      amount: transaction.amountValue,
                      date: transaction.dateValue)
    }
    
    private func isOutgoing(_ transaction: Transactions.TransactionModel) -> Bool {
        return transaction.senderId.lowercased() == lskWalletService.wallet?.address.lowercased()
    }
}

extension Transactions.TransactionModel: TransactionDetails {
    var txId: String {
        return id
    }
    
    var dateValue: Date? {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp) + Constants.Time.epochSeconds)
    }
    
    var amountValue: Decimal {
        let value = BigUInt(self.amount) ?? BigUInt(0)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee) ?? BigUInt(0)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var confirmationsValue: String? {
        return "\(self.confirmations)"
    }
    
    var blockValue: String? {
        return self.blockId
    }
    
    var isOutgoing: Bool {
        return false
    }
    
    var transactionStatus: TransactionStatus? {
        if confirmations > 100 {
            return .success
        }
        return .pending
    }
    
    var senderAddress: String {
        return self.senderId
    }

    var recipientAddress: String {
        return self.recipientId ?? ""
    }

    var sentDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp) + Constants.Time.epochSeconds)
    }
}

extension LocalTransaction: TransactionDetails {
    var txId: String {
        return id ?? ""
    }
    
    var senderAddress: String {
        return self.senderPublicKey ?? ""
    }
    
    var recipientAddress: String {
        return self.recipientId ?? ""
    }
    
    var dateValue: Date? {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp) + Constants.Time.epochSeconds)
    }
    
    var amountValue: Decimal {
        let value = BigUInt(self.amount)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var confirmationsValue: String? {
        return nil
    }
    
    var blockValue: String? {
        return nil
    }
    
    var isOutgoing: Bool {
        return true
    }
    
    var transactionStatus: TransactionStatus? {
        return .pending
    }
    
}
