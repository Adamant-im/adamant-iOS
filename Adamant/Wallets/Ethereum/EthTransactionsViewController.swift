//
//  EthTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import web3swift

class EthTransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var ethWalletService: EthWalletService! {
        didSet {
            ethAddress = ethWalletService.wallet?.address ?? ""
        }
    }
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [EthTransactionShort] = []
    private var ethAddress: String = ""
    private var offset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        currencySymbol = EthWalletService.currencySymbol
        
        handleRefresh()
    }
    
    // MARK: - Overrides
    
    override func handleRefresh() {
        offset = 0
        transactions.removeAll()
        tableView.reloadData()
        loadData(false)
    }
    
    override func loadData(_ silent: Bool) {
        isBusy = true
        emptyLabel.isHidden = true
        
        guard let address = ethWalletService.wallet?.address else {
            transactions = []
            return
        }
        
        Task { @MainActor in
            do {
                let trs = try await ethWalletService.getTransactionsHistory(
                    address: address,
                    offset: offset
                )
                
                transactions.append(contentsOf: trs)
                offset += trs.count
                isNeedToLoadMoore = trs.count > 0
            } catch {
                isNeedToLoadMoore = false
                
                if !silent {
                    dialogService.showRichError(error: error)
                }
            }
            
            isBusy = false
            emptyLabel.isHidden = transactions.count > 0
            refreshControl.endRefreshing()
            stopBottomIndicator()
            tableView.reloadData()
        }.stored(in: taskManager)
    }
    
    override func reloadData() {
        DispatchQueue.onMainAsync { [weak self] in
            self?.refreshControl.beginRefreshing()
        }
        
        handleRefresh()
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = ethWalletService.wallet?.address
        
        tableView.deselectRow(at: indexPath, animated: true)
        let hash = transactions[indexPath.row].hash
        
        guard let dialogService = dialogService else {
            return
        }
        
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
            fatalError("Failed to get EthTransactionDetailsViewController")
        }
        
        vc.service = ethWalletService
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        Task {
            do {
                let ethTransaction = try await ethWalletService.getTransaction(by: hash)
                dialogService.dismissProgress()
                
                vc.transaction = ethTransaction
                
                if let address = address {
                    if ethTransaction.senderAddress.caseInsensitiveCompare(address) == .orderedSame {
                        vc.senderName = String.adamantLocalized.transactionDetails.yourAddress
                    } else if ethTransaction.recipientAddress.caseInsensitiveCompare(address) == .orderedSame {
                        vc.recipientName = String.adamantLocalized.transactionDetails.yourAddress
                    }
                }
                
                navigationController?.pushViewController(vc, animated: true)
            } catch {
                dialogService.dismissProgress()
                dialogService.showRichError(error: error)
            }
        }.stored(in: taskManager)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifierCompact, for: indexPath) as? TransactionTableViewCell else {
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: EthTransactionShort) {
        let outgoing = isOutgoing(transaction)
        let partnerId = outgoing ? transaction.to : transaction.from
        
        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId,
                      partnerName: nil,
                      amount: transaction.value,
                      date: transaction.date)
    }
}

// MARK: - Tools
extension EthTransactionsViewController {
    private func isOutgoing(_ transaction: EthTransactionShort) -> Bool {
        return transaction.from.lowercased() == ethAddress.lowercased()
    }
}
