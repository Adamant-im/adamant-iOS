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

class ERC20TransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var ercWalletService: ERC20WalletService! {
        didSet {
            ethAddress = ercWalletService.wallet?.address ?? ""
        }
    }
    var router: Router!
    
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
        
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController else {
            fatalError("Failed to get ERC20TransactionDetailsViewController")
        }
        
        vc.service = ercWalletService
        
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
        
        vc.transaction = emptyTransaction
        
        if emptyTransaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
            vc.senderName = String.adamant.transactionDetails.yourAddress
        }
        
        if emptyTransaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
            vc.recipientName = String.adamant.transactionDetails.yourAddress
        }
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
