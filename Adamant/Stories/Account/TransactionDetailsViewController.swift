//
//  TransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class TransactionDetailsViewController: UIViewController {
	private enum Row: Int {
		case amount = 0
		case date
		case confirmations
		case fee
		case transactionNumber
		case from
		case to
		
		static let total = 7
	}
	
	// MARK: - Dependencies
	var apiService: ApiService!
	
	
	// MARK: - Properties
	var transaction: Transaction?
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
		tableView.dataSource = self
		tableView.delegate = self
		
		if transaction != nil {
			tableView.reloadData()
		}
	}
}


// MARK: - UITableView
extension TransactionDetailsViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if transaction != nil {
			return Row.total
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}
}


// MARK: - UITableView Cells
extension TransactionDetailsViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let transaction = transaction, let row = Row(rawValue: indexPath.row) else {
			// TODO: Display & Log error
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		var cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: "cell") {
			cell = c
		} else {
			cell = UITableViewCell(style: .value1, reuseIdentifier: "cell")
			cell.textLabel?.textColor = UIColor.adamantPrimary
			cell.detailTextLabel?.textColor = UIColor.adamantSecondary
			
			let font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.font = font
			cell.detailTextLabel?.font = font
		}
		
		switch row {
		case .amount:
			cell.textLabel?.text = "Amount"
			cell.detailTextLabel?.text = AdamantUtilities.format(balance: transaction.amount)
			
		case .date:
			cell.textLabel?.text = "Date"
			cell.detailTextLabel?.text = DateFormatter.localizedString(from: transaction.date, dateStyle: .short, timeStyle: .medium)
			
		case .confirmations:
			cell.textLabel?.text = "Confirmations"
			cell.detailTextLabel?.text = String(transaction.confirmations)
			
		case .fee:
			cell.textLabel?.text = "Fee"
			cell.detailTextLabel?.text = AdamantUtilities.format(balance: transaction.fee)
			
		case .transactionNumber:
			cell.textLabel?.text = "Transaction #"
			cell.detailTextLabel?.text = String(transaction.id)
			
		case .from:
			cell.textLabel?.text = "From"
			cell.detailTextLabel?.text = transaction.senderId
			
		case .to:
			cell.textLabel?.text = "To"
			cell.detailTextLabel?.text = transaction.recipientId
		}
		
		return cell
	}
}
