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
		case transactionNumber = 0
		case from
		case to
		case date
		case amount
		case fee
		case confirmations
		case block
		case openInExplorer
		
		static let total = 9
	}
	
	// MARK: - Dependencies
	var dialogService: DialogService!
	
	// MARK: - Properties
	var transaction: Transaction?
	var explorerUrl: URL!
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	override func viewDidLoad() {
		tableView.dataSource = self
		tableView.delegate = self
		
		if let transaction = transaction {
			tableView.reloadData()
			
			explorerUrl = URL(string: "https://explorer.adamant.im/tx/\(transaction.id)")
		} else {
			self.navigationItem.rightBarButtonItems = nil
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
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
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == Row.openInExplorer.rawValue,
			let url = explorerUrl {
			let safari = SFSafariViewController(url: url)
			safari.preferredControlTintColor = UIColor.adamantPrimary
			present(safari, animated: true, completion: nil)
			return
		}
		
		guard let cell = tableView.cellForRow(at: indexPath),
			let row = Row(rawValue: indexPath.row),
			let details = cell.detailTextLabel?.text else {
			tableView.deselectRow(at: indexPath, animated: true)
			return
		}
		
		let payload: String
		switch row {
		case .amount:
			payload = "Amount: \(details)"
			
		case .date:
			payload = "Date: \(details)"
			
		case .confirmations:
			payload = "Confirmations: \(details)"
			
		case .fee:
			payload = "Fee: \(details)"
			
		case .transactionNumber:
			payload = "Id: \(details)"
			
		case .from:
			payload = "Sender: \(details)"
			
		case .to:
			payload = "Recipient: \(details)"
			
		case .block:
			payload = "Block Id: \(details)"
			
		case .openInExplorer:
			payload = ""
		}
		
		dialogService.presentCopyOrShareAlert(for: payload, animated: true) {
			tableView.deselectRow(at: indexPath, animated: true)
		}
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
			cell.accessoryType = .none
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
			
		case .block:
			cell.textLabel?.text = "Block"
			cell.detailTextLabel?.text = String(transaction.blockId)
			
		case .openInExplorer:
			cell.textLabel?.text = "Open in Blockchain Explorer"
			cell.detailTextLabel?.text = nil
			cell.accessoryType = .disclosureIndicator
		}
		
		return cell
	}
}
