//
//  DogeTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 11/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import ProcedureKit
import CommonKit

final class DogeTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var dogeWalletService: DogeWalletService!
    var screensFactory: ScreensFactory!
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = walletService.wallet?.address,
              let transaction = transactions[safe: indexPath.row]
        else { return }
        
        let controller = screensFactory.makeDetailsVC(service: dogeWalletService)
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

private class LoadMoreDogeTransactionsProcedure: Procedure {
    let from: Int
    let service: DogeWalletService
    
    private(set) var result: (transactions: [DogeTransaction], hasMore: Bool)?
    
    init(service: DogeWalletService, from: Int) {
        self.from = from
        self.service = service
        
        super.init()
        log.severity = .warning
    }
    
    override func execute() {
        Task {
            do {
                let result = try await service.getTransactions(from: from)
                self.result = result
                self.finish()
            } catch {
                self.result = nil
                self.finish(with: error)
            }
        }
    }
}
