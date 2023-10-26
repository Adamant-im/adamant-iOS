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
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let address = btcWalletService.wallet?.address,
              let transaction = transactions[safe: indexPath.row]
        else { return }
        
        let controller = screensFactory.makeDetailsVC(service: btcWalletService)
        
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
