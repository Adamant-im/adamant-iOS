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
    var transactions: [EthTransaction] = []
    private var ethAddress: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        currencySymbol = EthWalletService.currencySymbol
        
        handleRefresh(self.refreshControl)
    }
	
    
    // MARK: - Overrides
    
    override func handleRefresh(_ refreshControl: UIRefreshControl) {
		guard let address = ethWalletService.wallet?.address else {
			transactions = []
			return
		}
		
		ethWalletService.getTransactionsHistory(address: address) { [weak self] result in
			guard let vc = self else {
				return
			}

			switch result {
			case .success(let transactions):
				vc.transactions = transactions

			case .failure(let error):
				vc.transactions = []
				vc.dialogService.showRichError(error: error)
			}

			DispatchQueue.main.async {
				vc.tableView.reloadData()
				vc.refreshControl.endRefreshing()
			}
		}
    }
    
    override func reloadData() {
        if Thread.isMainThread {
            refreshControl.beginRefreshing()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.refreshControl.beginRefreshing()
            }
        }
        
        handleRefresh(refreshControl)
    }
    
    // MARK: - UITableView
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? TransactionDetailsViewControllerBase else {
            return
        }

//        controller.transaction = transaction
        navigationController?.pushViewController(controller, animated: true)
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
    
    func configureCell(_ cell: TransactionTableViewCell, for transaction: EthTransaction) {
        let outgoing = isOutgoing(transaction)
        let partnerId = outgoing ? transaction.to : transaction.from
        
        configureCell(cell,
                      isOutgoing: outgoing,
                      partnerId: partnerId,
                      partnerName: nil,
                      amount: transaction.value, //.asDecimal(exponent: EthWalletService.currencyExponent),
                      date: transaction.date)
    }
}


// MARK: - Tools
extension EthTransactionsViewController {
    private func isOutgoing(_ transaction: EthTransaction) -> Bool {
        return transaction.from.lowercased() == ethAddress.lowercased()
    }
}
