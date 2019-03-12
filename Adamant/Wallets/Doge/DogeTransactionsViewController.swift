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
        self.walletService.getTransactions({ (result) in
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
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Doge.transactionDetails) as? DogeTransactionDetailsViewController else {
            return
        }
        
        controller.transaction = transaction
        controller.service = walletService
        
        if let address = walletService.wallet?.address {
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: DogeTransaction) {
        let outgoing = isOutgoing(transaction)
        let partnerId = outgoing ? transaction.recipientAddress : transaction.senderAddress
        
        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId ?? "",
                      partnerName: nil,
                      amount: transaction.amountValue,
                      date: transaction.dateValue)
    }
    
    private func isOutgoing(_ transaction: DogeTransaction) -> Bool {
        return transaction.senderAddress.lowercased() == walletService.wallet?.address.lowercased()
    }
}

class DogeTransaction: TransactionDetails {
    var txId: String = ""
    var senderAddress: String = ""
    var recipientAddress: String = ""
    var dateValue: Date?
    var amountValue: Decimal = 0
    var feeValue: Decimal?
    var confirmationsValue: String?
    var blockValue: String? = nil
    var isOutgoing: Bool = false
    var transactionStatus: TransactionStatus?
    
    static func from(_ dictionry: [String: Any], with walletAddress: String) -> DogeTransaction  {
        let transaction = DogeTransaction()
        
        if let txid = dictionry["txid"] as? String { transaction.txId = txid }
        if let vin = dictionry["vin"] as? [[String: Any]], let input = vin.first, let address = input["addr"] as? String {
            transaction.senderAddress = address
            if address == walletAddress {
                transaction.isOutgoing = true
            }
        }
        if let vout = dictionry["vout"] as? [[String: Any]] {
            let outputs = vout.filter { item -> Bool in
                if let publickKey = item["scriptPubKey"] as? [String: Any], let addresses = publickKey["addresses"] as? [String], let address = addresses.first {
                    if transaction.isOutgoing, address != walletAddress {
                        return true
                    } else if !transaction.isOutgoing, address == walletAddress {
                        return true
                    }
                }
                return false
            }
            if let output = outputs.first, let publickKey = output["scriptPubKey"] as? [String: Any], let addresses = publickKey["addresses"] as? [String], let address = addresses.first, let valueRaw = output["value"] as? String, let value = Decimal(string: valueRaw) {
                transaction.recipientAddress = address
                transaction.amountValue = value
            }
        }
        if let time = dictionry["time"] as? NSNumber { transaction.dateValue = Date(timeIntervalSince1970: time.doubleValue) }
        if let fees = dictionry["fees"] as? NSNumber { transaction.feeValue = fees.decimalValue }
        if let confirmations = dictionry["confirmations"] as? NSNumber { transaction.confirmationsValue = confirmations.stringValue }
        if let blockhash = dictionry["blockhash"] as? String { transaction.blockValue = blockhash }
        
        transaction.transactionStatus = TransactionStatus.success
        
        return transaction
    }
}
