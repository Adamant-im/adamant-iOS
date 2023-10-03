//
//  BtcTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 30/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import BitcoinKit
import CommonKit

final class BtcTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var btcWalletService: BtcWalletService!
    var screensFactory: ScreensFactory!
    var addressBook: AddressBookService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = BtcWalletService.currencySymbol
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        let controller = screensFactory.makeDetailsVC(service: btcWalletService)
        
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

        if let address = btcWalletService.wallet?.address {
            if transaction.senderId?.caseInsensitiveCompare(address) == .orderedSame {
                controller.senderName = String.adamant.transactionDetails.yourAddress
            }
            if transaction.recipientId?.caseInsensitiveCompare(address) == .orderedSame {
                controller.recipientName = String.adamant.transactionDetails.yourAddress
            }
        }

        navigationController?.pushViewController(controller, animated: true)
    }
}
