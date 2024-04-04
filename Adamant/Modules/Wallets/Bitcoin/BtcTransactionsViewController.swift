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
    
    private let addressBook: AddressBookService
    
    // MARK: - Init
    
    init(
        walletService: WalletService,
        dialogService: DialogService,
        reachabilityMonitor: ReachabilityMonitor,
        screensFactory: ScreensFactory,
        addressBook: AddressBookService
    ) {
        self.addressBook = addressBook
        
        super.init(
            walletService: walletService,
            dialogService: dialogService,
            reachabilityMonitor: reachabilityMonitor,
            screensFactory: screensFactory
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
