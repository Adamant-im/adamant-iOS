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
    var walletService: DashWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [DashTransaction] = []
    private var allTransactionsIds: [String] = []
    private var offset = 0
    private var maxPerRequest = 25
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLoadingView(isHidden: false)
        currencySymbol = DashWalletService.currencySymbol
        handleRefresh()
    }
    
    override func handleRefresh() {
        transactions.removeAll()
        tableView.reloadData()
        allTransactionsIds.removeAll()
        offset = 0
        
        loadData(silent: true)
    }
    
    override func loadData(silent: Bool) {
        guard let address = walletService.wallet?.address else {
            transactions = []
            return
        }
        
        isBusy = true
        emptyLabel.isHidden = true
        
        Task { @MainActor in
            do {
                if allTransactionsIds.isEmpty {
                    allTransactionsIds = try await walletService.requestTransactionsIds(for: address).reversed()
                }
                
                let availableToLoad = allTransactionsIds.count - offset
                
                let maxPerRequest = availableToLoad > maxPerRequest
                ? maxPerRequest
                : availableToLoad
                
                let ids = Array(allTransactionsIds[offset..<(offset + maxPerRequest)])
                
                let trs = try await walletService.getTransactions(by: ids)
                
                transactions.append(contentsOf: trs)
                offset += trs.count
                isNeedToLoadMoore = allTransactionsIds.count - offset > 0
            } catch {
                isNeedToLoadMoore = false
                
                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = transactions.count > 0
            stopBottomIndicator()
            refreshControl.endRefreshing()
            tableView.reloadData()
            updateLoadingView(isHidden: true)
        }.stored(in: taskManager)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let controller = router.get(scene: AdamantScene.Wallets.Dash.transactionDetails) as? DashTransactionDetailsViewController else {
            fatalError("Failed to getDashTransactionDetailsViewController")
        }

        // Hold reference
        guard let address = walletService.wallet?.address else {
            return
        }

        controller.service = self.walletService
        
        let transaction = transactions[indexPath.row]
        
        let isOutgoing: Bool = transaction.recipientAddress != address
        
        let emptyTransaction = SimpleTransactionDetails(
            txId: transaction.txId,
            senderAddress: transaction.senderAddress,
            recipientAddress: transaction.recipientAddress,
            dateValue: nil,
            amountValue: transaction.amountValue,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: isOutgoing,
            transactionStatus: nil
        )
        
        controller.transaction = emptyTransaction
        
        if emptyTransaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
        }
        
        if emptyTransaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
            controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
        }
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as? TransactionTableViewCell else {
            // TODO: Display & Log error
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        cell.separatorInset = indexPath.row == transactions.count - 1
        ? .zero
        : UITableView.defaultTransactionsSeparatorInset
        
        configureCell(cell, for: transaction)
        return cell
    }
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: BaseBtcTransaction) {
        let outgoing = transaction.isOutgoing
        let partnerId = outgoing ? transaction.recipientAddress : transaction.senderAddress

        let partnerName: String?
        if let address = walletService.wallet?.address, partnerId == address {
            partnerName = String.adamantLocalized.transactionDetails.yourAddress
        } else {
            partnerName = nil
        }

        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId,
                      partnerName: partnerName,
                      amount: transaction.amountValue ?? 0,
                      date: transaction.dateValue)
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
