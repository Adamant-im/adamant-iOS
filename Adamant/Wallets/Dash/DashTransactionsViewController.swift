//
//  DashTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import ProcedureKit

class DashTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var dashWalletService: DashWalletService!
    var router: Router!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currencySymbol = DashWalletService.currencySymbol
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            fatalError("Failed to getDashTransactionDetailsViewController")
        }
        
        // Hold reference
        guard let address = dashWalletService.wallet?.address else {
            return
        }
        
        controller.service = self.dashWalletService
        
        let transaction = transactions[indexPath.row]
        
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

private class LoadMoreDashTransactionsProcedure: Procedure {
    let service: DashWalletService
    
    private(set) var result: DashTransactionsPointer?
    
    init(service: DashWalletService) {
        self.service = service
        
        super.init()
        
        log.severity = .warning
    }
    
    override func execute() {
        service.getNextTransaction { result in
            switch result {
            case .success(let result):
                self.result = result
                self.finish()
                
            case .failure(let error):
                self.result = nil
                self.finish(with: error)
            }
        }
    }
}
