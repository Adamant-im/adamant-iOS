//
//  KlyTransactionsViewController.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 09.07.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import UIKit
import LiskKit
import web3swift
import BigInt
import CommonKit
import Combine

final class KlyTransactionsViewController: TransactionsListViewControllerBase {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let address = walletService.core.wallet?.address,
              let transaction = transactions[safe: indexPath.row]
        else { return }
        
        let controller = screensFactory.makeDetailsVC(service: walletService)
        
        controller.transaction = transaction
        
        if transaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.senderName = String.adamant.transactionDetails.yourAddress
        }
        
        if transaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.recipientName = String.adamant.transactionDetails.yourAddress
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension Transactions.TransactionModel: TransactionDetails, @unchecked @retroactive Sendable {
    var nonceRaw: String? {
        return self.nonce
    }
    
    var defaultCurrencySymbol: String? { KlyWalletService.currencySymbol }
    
    var txId: String {
        return id
    }
    
    var dateValue: Date? {
        return timestamp.map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }
    
    var amountValue: Decimal? {
        let value = BigUInt(self.amount) ?? BigUInt(0)
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee) ?? BigUInt(0)
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
    }
    
    var confirmationsValue: String? {
        guard let confirmations = confirmations,
              let height = height,
              confirmations >= height
        else { return "0" }
        
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
        guard let confirmations = confirmations,
              let height = height,
              confirmations > .zero
        else { return .notInitiated }
        
        if confirmations < height { return .registered }
        
        guard executionStatus != .failed else {
            return .failed
        }
        
        if confirmations > 0 && height > 0 {
            let conf = (confirmations - height) + 1
            if conf > 1 {
                return .success
            } else {
                return .pending
            }
        }
        return .notInitiated
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
    
    var txBlockchainComment: String? {
        txData
    }
}

extension LocalTransaction: TransactionDetails, @unchecked @retroactive Sendable {

    var defaultCurrencySymbol: String? { KlyWalletService.currencySymbol }
    
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
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee)
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
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
        return .notInitiated
    }
    
    var nonceRaw: String? {
        nil
    }
}

extension TransactionEntity: TransactionDetails {
    
    var defaultCurrencySymbol: String? { KlyWalletService.currencySymbol }
    
    var txId: String {
        return id
    }
    
    var recipientAddress: String {
        recipientAddressBase32
    }
    
    var dateValue: Date? {
        return nil
    }
    
    var amountValue: Decimal? {
        let value = BigUInt(self.params.amount)
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
    }
    
    var feeValue: Decimal? {
        let value = BigUInt(self.fee)
        
        return value.asDecimal(exponent: KlyWalletService.currencyExponent)
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
        return .notInitiated
    }
    
    var nonceRaw: String? {
        String(nonce)
    }
}
