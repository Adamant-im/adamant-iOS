//
//  EthTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import web3swift
import CommonKit

final class EthTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var ethWalletService: EthWalletService! {
        didSet {
            ethAddress = ethWalletService.wallet?.address ?? ""
        }
    }
    var screensFactory: ScreensFactory!
    
    // MARK: - Properties
    private var ethAddress: String = ""
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = ethWalletService.wallet?.address else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let transaction = transactions[indexPath.row]
        let vc = screensFactory.makeDetailsVC(service: ethWalletService)
        
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
