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
    var ercWalletService: ERC20WalletService! {
        didSet {
            ethAddress = ercWalletService.wallet?.address ?? ""
        }
    }
    var screensFactory: ScreensFactory!
    
    // MARK: - Properties

    private var ethAddress: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = walletService.tokenSymbol
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = walletService.wallet?.address else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        let vc = screensFactory.makeDetailsVC(service: ercWalletService)
        
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
