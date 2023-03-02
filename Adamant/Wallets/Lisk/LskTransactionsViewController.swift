//
//  LskTransactionsViewController
//  Adamant
//
//  Created by Anton Boyarkin on 17/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import LiskKit
import web3swift
import BigInt

class LskTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var lskWalletService: LskWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [Transactions.TransactionModel] = []
    
    private var offset: UInt = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.beginRefreshing()
        
        currencySymbol = LskWalletService.currencySymbol
        
        loadData(true)
    }
    
    override func handleRefresh() {
        self.emptyLabel.isHidden = true
        tableView.reloadData()
        transactions.removeAll()
        tableView.reloadData()
        offset = 0
        loadData(false)
    }
    
    override func loadData(_ silent: Bool) {
        isBusy = true
        Task { @MainActor in
            do {
                let trs = try await lskWalletService.getTransactions(offset: offset)
                transactions.append(contentsOf: trs)
                offset += UInt(trs.count)
                isNeedToLoadMoore = trs.count > 0
                tableView.reloadData()
            } catch {
                isNeedToLoadMoore = false
                
                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = self.transactions.count > 0
            stopBottomIndicator()
            refreshControl.endRefreshing()
        }.stored(in: taskManager)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Lisk.transactionDetails) as? LskTransactionDetailsViewController else {
            return
        }
        
        controller.transaction = transaction
        controller.service = lskWalletService
        
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
                      amount: transaction.amountValue ?? 0,
                      date: transaction.dateValue)
    }
    
    private func isOutgoing(_ transaction: Transactions.TransactionModel) -> Bool {
        return transaction.senderId.lowercased() == lskWalletService.wallet?.address.lowercased()
    }
}

extension Transactions.TransactionModel: TransactionDetails {
    
    static var defaultCurrencySymbol: String? { return LskWalletService.currencySymbol }
    
    var txId: String {
        return id
    }
    
    var dateValue: Date? {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp))
    }
    
    var amountValue: Decimal? {
        let value = BigUInt(self.amount) ?? BigUInt(0)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee) ?? BigUInt(0)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var confirmationsValue: String? {
        guard let confirmations = confirmations else { return "0" }
        if confirmations < self.height { return "0" }
        if confirmations > 0 {
            return "\(confirmations - self.height + 1)"
        }
        
        return "\(confirmations)"
    }
    
    var blockHeight: UInt64? {
        return self.height
    }
    
    var blockValue: String? {
        return self.blockId
    }
    
    var isOutgoing: Bool {
        return false
    }
    
    var transactionStatus: TransactionStatus? {
        guard let confirmations = confirmations else { return .pending }
        if confirmations < self.height { return .pending }
        
        if confirmations > 0 && self.height > 0 {
            let conf = (confirmations - self.height) + 1
            if conf > 1 {
                return .success
            } else {
                return .pending
            }
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
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp))
    }
}

extension LocalTransaction: TransactionDetails {

    static var defaultCurrencySymbol: String? { return LskWalletService.currencySymbol }
    
    var txId: String {
        return id ?? ""
    }
    
    var senderAddress: String {
        return ""
    }
    
    var recipientAddress: String {
        return self.recipientId ?? ""
    }
    
    var dateValue: Date? {
        return Date(timeIntervalSince1970: TimeInterval(self.timestamp))
    }
    
    var amountValue: Decimal? {
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
    
    var blockHeight: UInt64? {
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

extension TransactionEntity: TransactionDetails {
    
    static var defaultCurrencySymbol: String? { return LskWalletService.currencySymbol }
    
    var txId: String {
        return id
    }
    
    var senderAddress: String {
        return LiskKit.Crypto.getBase32Address(from: senderPublicKey)
    }
    
    var recipientAddress: String {
        return self.asset.recipientAddress
    }
    
    var dateValue: Date? {
        return nil
    }
    
    var amountValue: Decimal? {
        let value = BigUInt(self.asset.amount)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee)
        
        return value.asDecimal(exponent: LskWalletService.currencyExponent)
    }
    
    var confirmationsValue: String? {
        return nil
    }
    
    var blockHeight: UInt64? {
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
