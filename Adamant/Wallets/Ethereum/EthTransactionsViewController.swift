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
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [EthTransactionShort] = []
    private var ethAddress: String = ""
    private var offset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLoadingView(isHidden: false)
        currencySymbol = EthWalletService.currencySymbol
        handleRefresh()
    }
    
    // MARK: - Overrides
    
    override func handleRefresh() {
        offset = 0
        transactions.removeAll()
        tableView.reloadData()
        loadData(silent: false)
    }
    
    override func loadData(silent: Bool) {
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
            updateLoadingView(isHidden: true)
        }.stored(in: taskManager)
    }
    
    override func reloadData() {
        handleRefresh()
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let address = ethWalletService.wallet?.address else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        let transaction = transactions[indexPath.row]
        
        guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? EthTransactionDetailsViewController else {
            fatalError("Failed to get EthTransactionDetailsViewController")
        }
        
        vc.service = ethWalletService
        
        let isOutgoing: Bool = transaction.to != address
        
        let emptyTransaction = SimpleTransactionDetails(
            txId: transaction.hash,
            senderAddress: transaction.from,
            recipientAddress: transaction.to,
            dateValue: nil,
            amountValue: transaction.value,
            feeValue: nil,
            confirmationsValue: nil,
            blockValue: nil,
            isOutgoing: isOutgoing,
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
