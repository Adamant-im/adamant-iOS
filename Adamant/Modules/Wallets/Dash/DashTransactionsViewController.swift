//
//  DashTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import ProcedureKit

final class DashTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var screensFactory: ScreensFactory!
    var dashWalletService: DashWalletService!
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = walletService.wallet?.address,
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
