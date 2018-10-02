//
//  ETHTransactionsViewController.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class ETHTransactionsViewController: TransactionsViewController {
    
    // MARK: - Dependencies
    var ethWalletService: EthWalletService!
    var dialogService: DialogService!
    var router: Router!
    
    // MARK: - Properties
    var transactions: [EthTransaction] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.beginRefreshing()
        
        handleRefresh(self.refreshControl)
    }
	
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
    
    override func currentAddress() -> String {
        guard let address = ethWalletService.wallet?.address else {
            return ""
        }
        return address
    }
}

// MARK: - UITableView
extension ETHTransactionsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let transaction = transactions[indexPath.row]
        
        guard let controller = router.get(scene: AdamantScene.Wallets.Ethereum.transactionDetails) as? TransactionDetailsViewControllerBase else {
            return
        }

        controller.transaction = transaction
        navigationController?.pushViewController(controller, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransactionTableViewCell else {
                // TODO: Display & Log error
                return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let transaction = transactions[indexPath.row]
        
        cell.accessoryType = .disclosureIndicator
        
        configureCell(cell, for: transaction)
        return cell
    }
}
