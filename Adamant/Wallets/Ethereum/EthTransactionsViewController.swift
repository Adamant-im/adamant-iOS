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

class EthTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var ethWalletService: EthWalletService! {
        didSet {
            ethAddress = ethWalletService.wallet?.address ?? ""
        }
    }
    var router: Router!
    
    // MARK: - Properties
    private var ethAddress: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = EthWalletService.currencySymbol
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = ethWalletService.wallet?.address else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let transaction = transactions[indexPath.row]
        
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
            fatalError("Failed to get EthTransactionDetailsViewController")
        }
        
        vc.service = ethWalletService
        
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
