//
//  ERC20TransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import web3swift
import CommonKit

final class ERC20TransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    
    var screensFactory: ScreensFactory!
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = walletService.core.wallet?.address,
              let transaction = transactions[safe: indexPath.row]
        else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
                
        let vc = screensFactory.makeDetailsVC(service: walletService)
        
        vc.transaction = transaction
        
        if transaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
            vc.senderName = String.adamant.transactionDetails.yourAddress
        }
        
        if transaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
            vc.recipientName = String.adamant.transactionDetails.yourAddress
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
