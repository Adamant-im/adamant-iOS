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
import Combine

final class LskTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var lskWalletService: LskWalletService!
    var screensFactory: ScreensFactory!
    
    // MARK: - Properties
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = LskWalletService.currencySymbol
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let address = lskWalletService.wallet?.address else { return }
        
        let transaction = transactions[indexPath.row]
        let controller = screensFactory.makeDetailsVC(service: lskWalletService)
        
        let emptyTransaction = SimpleTransactionDetails(
            txId: transaction.transactionId,
            senderAddress: transaction.senderId ?? "",
            recipientAddress: transaction.recipientId ?? "",
            dateValue: transaction.date as? Date,
            amountValue: transaction.amount?.decimalValue,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: transaction.isOutgoing,
            transactionStatus: nil
        )
        
        controller.transaction = emptyTransaction
        
        if emptyTransaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.senderName = String.adamant.transactionDetails.yourAddress
        }
        
        if emptyTransaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.recipientName = String.adamant.transactionDetails.yourAddress
        }
        
        navigationController?.pushViewController(controller, animated: true)
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
        return self.asset.recipientAddressBase32
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
