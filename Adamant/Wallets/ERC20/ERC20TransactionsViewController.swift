//
//  ERC20TransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import web3swift

class ERC20TransactionsViewController: TransactionsListViewControllerBase {
    
    // MARK: - Dependencies
    var walletService: ERC20WalletService! {
        didSet {
            ethAddress = walletService.wallet?.address ?? ""
        }
    }
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [EthTransactionShort] = []
    private var ethAddress: String = ""
    private lazy var exponent: Int = {
        var exponent = EthWalletService.currencyExponent
        if let naturalUnits = walletService.token?.naturalUnits {
            exponent = -1 * naturalUnits
        }
        return exponent
    }()
    private var offset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        currencySymbol = walletService.tokenSymbol
        
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
        
        guard let address = walletService.wallet?.address else {
            transactions = []
            return
        }
        
        Task { @MainActor in
            do {
                let trs = try await walletService.getTransactionsHistory(
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
            tableView.reloadData()
            stopBottomIndicator()
            refreshControl.endRefreshing()
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
        let address = walletService.wallet?.address
        
        tableView.deselectRow(at: indexPath, animated: true)
        let hash = transactions[indexPath.row].hash
        
        guard let dialogService = dialogService else {
            return
        }
        
        guard let vc = router.get(scene: AdamantScene.Wallets.ERC20.transactionDetails) as? ERC20TransactionDetailsViewController else {
            fatalError("Failed to get ERC20TransactionDetailsViewController")
        }
        
        vc.service = walletService
        
        dialogService.showProgress(withMessage: nil, userInteractionEnable: false)
        
        Task {
            do {
                let ethTransaction = try await walletService.getTransaction(by: hash)
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
                      amount: transaction.contract_value.asDecimal(exponent: exponent),
                      date: transaction.date)
    }
}

// MARK: - Tools
extension ERC20TransactionsViewController {
    private func isOutgoing(_ transaction: EthTransactionShort) -> Bool {
        return transaction.from.lowercased() == ethAddress.lowercased()
    }
}
