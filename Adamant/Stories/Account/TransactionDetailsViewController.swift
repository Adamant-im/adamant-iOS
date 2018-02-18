//
//  TransactionDetailsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices


// MARK: - Localization
extension String.adamantLocalized.alert {
	static let exportUrlButton = NSLocalizedString("URL", comment: "Export transaction: 'Share transaction URL' button")
	static let exportSummaryButton = NSLocalizedString("Summary", comment: "Export transaction: 'Share transaction summary' button")
}


// MARK: - 
class TransactionDetailsViewController: UIViewController {
	fileprivate enum Row: Int {
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
		
		var localized: String {
			switch self {
			case .transactionNumber: return NSLocalizedString("Transaction #", comment: "Transaction Id row.")
			case .from: return NSLocalizedString("From", comment: "Transaction sender row.")
			case .to: return NSLocalizedString("To", comment: "Transaction recipient row.")
			case .date: return NSLocalizedString("Date", comment: "Transaction date row.")
			case .amount: return NSLocalizedString("Amount", comment: "Transaction amount row.")
			case .fee: return NSLocalizedString("Fee", comment: "Transaction fee row.")
			case .confirmations: return NSLocalizedString("Confirmations", comment: "Transaction confirmations row.")
			case .block: return NSLocalizedString("Block", comment: "Transaction Block id row.")
			case .openInExplorer: return NSLocalizedString("Open in Explorer", comment: "'Open transaction in explorer' row.")
			}
		}
	}
	
	// MARK: - Dependencies
	var dialogService: DialogService!
	var exportTools: ExportTools!
	
	// MARK: - Properties
	private let cellIdentifier = "cell"
	var transaction: Transaction?
	var explorerUrl: URL!
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var shareButton: UIBarButtonItem!
	
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
	
	@IBAction func share(_ sender: Any) {
		guard let transaction = transaction, let url = explorerUrl else {
			return
		}
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		// URL
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportUrlButton, style: .default) { _ in
			let alert = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			self.present(alert, animated: true, completion: nil)
		})
		
		// Description
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportSummaryButton, style: .default, handler: { _ in
			let text = self.exportTools.summaryFor(transaction: transaction, url: url)
			let alert = UIActivityViewController(activityItems: [text], applicationActivities: nil)
			self.present(alert, animated: true, completion: nil)
		}))
		
		present(alert, animated: true, completion: nil)
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
			payload = "\(row.localized): \(details)"
			
		case .date:
			payload = "\(row.localized): \(details)"
			
		case .confirmations:
			payload = "\(row.localized): \(details)"
			
		case .fee:
			payload = "\(row.localized): \(details)"
			
		case .transactionNumber:
			payload = "\(row.localized): \(details)"
			
		case .from:
			payload = "\(row.localized): \(details)"
			
		case .to:
			payload = "\(row.localized): \(details)"
			
		case .block:
			payload = "\(row.localized): \(details)"
			
		case .openInExplorer:
			payload = ""
		}
		
		dialogService.presentShareAlertFor(string: payload, types: [.copyToPasteboard, .share], animated: true) {
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
}


// MARK: - UITableView Cells
extension TransactionDetailsViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let transaction = transaction, let row = Row(rawValue: indexPath.row) else {
			// TODO: Display & Log error
			return UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
		}
		
		var cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
			cell = c
			cell.accessoryType = .none
		} else {
			cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
			cell.textLabel?.textColor = UIColor.adamantPrimary
			cell.detailTextLabel?.textColor = UIColor.adamantSecondary
			
			let font = UIFont.adamantPrimary(size: 17)
			cell.textLabel?.font = font
			cell.detailTextLabel?.font = font
		}
		
		cell.textLabel?.text = row.localized
		
		switch row {
		case .amount:
			cell.detailTextLabel?.text = AdamantUtilities.format(balance: transaction.amount)
			
		case .date:
			cell.detailTextLabel?.text = DateFormatter.localizedString(from: transaction.date, dateStyle: .short, timeStyle: .medium)
			
		case .confirmations:
			cell.detailTextLabel?.text = String(transaction.confirmations)
			
		case .fee:
			cell.detailTextLabel?.text = AdamantUtilities.format(balance: transaction.fee)
			
		case .transactionNumber:
			cell.detailTextLabel?.text = String(transaction.id)
			
		case .from:
			cell.detailTextLabel?.text = transaction.senderId
			
		case .to:
			cell.detailTextLabel?.text = transaction.recipientId
			
		case .block:
			cell.detailTextLabel?.text = String(transaction.blockId)
			
		case .openInExplorer:
			cell.detailTextLabel?.text = nil
			cell.accessoryType = .disclosureIndicator
		}
		
		return cell
	}
}
