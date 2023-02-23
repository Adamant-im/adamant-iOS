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
        currencySymbol = DashWalletService.currencySymbol
        
        refreshControl.beginRefreshing()
        handleRefresh()
    }
    
    override func handleRefresh() {
        transactions.removeAll()
        tableView.reloadData()
        allTransactionsIds.removeAll()
        offset = 0
        
        loadData(true)
    }
    
    override func loadData(_ silent: Bool) {
        guard let address = walletService.wallet?.address else {
            transactions = []
            return
        }
        
        isBusy = true
        emptyLabel.isHidden = true
        
        let task = Task { @MainActor in
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
            tableView.reloadData()
            stopBottomIndicator()
            refreshControl.endRefreshing()
        }
        
        taskManager.insert(task)
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
        guard let sender = walletService.wallet?.address else {
            return
        }

        controller.service = self.walletService
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        let txId = transactions[indexPath.row].txId

        Task { [weak self] in
            do {
                let dashTransaction = try await walletService.getTransaction(by: txId)
                guard let vc = self else {
                    return
                }

                let transaction = dashTransaction.asBtcTransaction(DashTransaction.self, for: sender)

                // Sender name
                if transaction.senderAddress == sender {
                    controller.senderName = String.adamantLocalized.transactionDetails.yourAddress
                }

                if transaction.recipientAddress == sender {
                    controller.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                }

                // Block Id
                guard let blockHash = dashTransaction.blockHash else {
                    controller.transaction = transaction
                    vc.navigationController?.pushViewController(controller, animated: true)
                    vc.tableView.deselectRow(at: indexPath, animated: true)
                    vc.dialogService.dismissProgress()
                    return
                }
                do {
                    let id = try await vc.walletService.getBlockId(by: blockHash)
                    controller.transaction = dashTransaction.asBtcTransaction(DashTransaction.self, for: sender, blockId: id)
                } catch {
                    controller.transaction = transaction
                }
                vc.tableView.deselectRow(at: indexPath, animated: true)
                vc.dialogService.dismissProgress()
                vc.navigationController?.pushViewController(controller, animated: true)
                
            } catch {
                self?.tableView.deselectRow(at: indexPath, animated: true)
                self?.dialogService.dismissProgress()
                self?.dialogService.showRichError(error: error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as? TransactionTableViewCell else {
            // TODO: Display & Log error
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        
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
