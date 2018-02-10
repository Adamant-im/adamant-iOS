//
//  TransactionsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class TransactionsViewController: UIViewController {
	// MARK: - Dependencies
	var cellFactory: CellFactory!
	var apiService: ApiService!
	
	
	// MARK: - Properties
	var account: String?
	private(set) var transactions: [Transaction]?
	private var updatingTransactions: Bool = false
	
	
	let transactionDetailsSegue = "showTransactionDetails"
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.register(cellFactory.nib(for: .TransactionCell), forCellReuseIdentifier: SharedCell.TransactionCell.cellIdentifier)
		tableView.dataSource = self
		tableView.delegate = self
		
		if account != nil {
			reloadTransactions()
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == transactionDetailsSegue,
			let vc = segue.destination as? TransactionDetailsViewController,
			let transaction = sender as? Transaction{
			vc.transaction = transaction
		}
	}
}


// MARK: - Recieving data
extension TransactionsViewController {
	func reloadTransactions() {
		guard !updatingTransactions else {
			return
		}
		
		transactions = nil
		
		guard let account = account else {
			tableView.reloadData()
			return
		}
		
		updatingTransactions = true
		
		apiService.getTransactions(forAccount: account, type: .send, fromHeight: nil) { (transactions, error) in
			defer {
				self.updatingTransactions = false
			}
			
			guard let transactions = transactions else {
				return
			}
			
			self.transactions = transactions.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
			
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}
}


// MARK: - UITableViewDataSource
extension TransactionsViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let transactions = transactions {
			return transactions.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return SharedCell.TransactionCell.defaultRowHeight
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let transaction = transactions?[indexPath.row] else {
			return
		}
		
		performSegue(withIdentifier: transactionDetailsSegue, sender: transaction)
	}
}


// MARK: - UITableView Cells
extension TransactionsViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let account = account, let transaction = transactions?[indexPath.row] else {
			// TODO: Display & Log error
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: SharedCell.TransactionCell.cellIdentifier, for: indexPath) as? TransactionTableViewCell else {
			// TODO: Display & Log error
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		cell.accountLabel.tintColor = UIColor.adamantPrimary
		cell.ammountLabel.tintColor = UIColor.adamantPrimary
		cell.dateLabel.tintColor = UIColor.adamantSecondary
		cell.avatarImageView.tintColor = UIColor.adamantPrimary
		
		if account == transaction.senderId {
			cell.transactionType = .outcome
			cell.accountLabel.text = transaction.recipientId
		} else {
			cell.transactionType = .income
			cell.accountLabel.text = transaction.senderId
		}
		
		cell.ammountLabel.text = AdamantUtilities.format(balance: transaction.amount)
		cell.dateLabel.text = DateFormatter.localizedString(from: transaction.date, dateStyle: .short, timeStyle: .medium)
		
		return cell
	}
}
