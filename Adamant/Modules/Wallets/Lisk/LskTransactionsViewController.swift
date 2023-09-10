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
import CommonKit

final class LskTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var lskWalletService: LskWalletService!
    var dialogService: DialogService!
    var screensFactory: ScreensFactory!
    
    // MARK: - Properties
    var transactions: [Transactions.TransactionModel] = []
    
    private var offset: UInt = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLoadingView(isHidden: false)
        currencySymbol = LskWalletService.currencySymbol
        handleRefresh()
    }
    
    override func handleRefresh() {
        emptyLabel.isHidden = true
        transactions.removeAll()
        tableView.reloadData()
        offset = 0
        loadData(silent: false)
    }
    
    override func loadData(silent: Bool) {
        isBusy = true
        Task { @MainActor in
            do {
                let trs = try await lskWalletService.getTransactions(offset: offset)
                transactions.append(contentsOf: trs)
                offset += UInt(trs.count)
                isNeedToLoadMoore = trs.count > 0
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
            tableView.reloadData()
            updateLoadingView(isHidden: true)
        }.stored(in: taskManager)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        let controller = screensFactory.makeDetailsVC(service: lskWalletService)
        
        let emptyTransaction = SimpleTransactionDetails(
            txId: transaction.txId,
            senderAddress: transaction.senderAddress,
            recipientAddress: transaction.recipientAddress,
            dateValue: transaction.dateValue,
            amountValue: transaction.amountValue,
            feeValue: transaction.feeValue,
            confirmationsValue: transaction.confirmationsValue,
            blockValue: transaction.blockValue,
            isOutgoing: transaction.isOutgoing,
            transactionStatus: nil
        )
        
        controller.transaction = emptyTransaction
        
        if let address = lskWalletService.wallet?.address {
            if transaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
                controller.senderName = String.adamant.transactionDetails.yourAddress
            } else if transaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
                controller.recipientName = String.adamant.transactionDetails.yourAddress
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
        cell.separatorInset = indexPath.row == transactions.count - 1
        ? .zero
        : UITableView.defaultTransactionsSeparatorInset
        
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
    
    var defaultCurrencySymbol: String? { LskWalletService.currencySymbol }
    
    var txId: String {
        return id
    }
    
    var dateValue: Date? {
        return timestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
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
        guard let confirmations = confirmations, let height = height else { return "0" }
        if confirmations < height { return "0" }
        if confirmations > 0 {
            return "\(confirmations - height + 1)"
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
        guard let confirmations = confirmations, let height = height else { return .registered }
        if confirmations < height { return .registered }
        
        if confirmations > 0 && height > 0 {
            let conf = (confirmations - height) + 1
            if conf > 1 {
                return .success
            } else {
                return .registered
            }
        }
        return .registered
    }
    
    var senderAddress: String {
        return self.senderId
    }

    var recipientAddress: String {
        return self.recipientId ?? ""
    }

    var sentDate: Date? {
        timestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
}

extension LocalTransaction: TransactionDetails {

    var defaultCurrencySymbol: String? { LskWalletService.currencySymbol }
    
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
    
    var defaultCurrencySymbol: String? { LskWalletService.currencySymbol }
    
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
