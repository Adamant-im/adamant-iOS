//
//  TransactionsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

class TransactionsViewController: UIViewController {
	// MARK: - Dependencies
	var cellFactory: CellFactory!
	var apiService: ApiService!
	var dialogService: DialogService!
	var transfersProvider: TransfersProvider!
	
	// MARK: - Properties
	private(set) var transactions: [Transaction]?
	private var updatingTransactions: Bool = false
	
	var controller: NSFetchedResultsController<TransferTransaction>?
	let transactionDetailsSegue = "showTransactionDetails"
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		controller = transfersProvider.transfersController()
		controller?.delegate = self
		
		
		tableView.register(cellFactory.nib(for: .TransactionCell), forCellReuseIdentifier: SharedCell.TransactionCell.cellIdentifier)
		tableView.dataSource = self
		tableView.delegate = self
		
		tableView.reloadData()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}

	// TODO:
//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		if segue.identifier == transactionDetailsSegue,
//			let vc = segue.destination as? TransactionDetailsViewController,
//			let transaction = sender as? Transaction{
//			vc.transaction = transaction
//		}
//	}
}

// MARK: - UITableView Cells
extension TransactionsViewController {
	private func configureCell(_ cell: TransactionTableViewCell, for transfer: TransferTransaction) {
		cell.accountLabel.tintColor = UIColor.adamantPrimary
		cell.ammountLabel.tintColor = UIColor.adamantPrimary
		cell.dateLabel.tintColor = UIColor.adamantSecondary
		cell.avatarImageView.tintColor = UIColor.adamantPrimary
		
		if transfer.isOutgoing {
			cell.transactionType = .outcome
			cell.accountLabel.text = transfer.recipientId
		} else {
			cell.transactionType = .income
			cell.accountLabel.text = transfer.senderId
		}
		
		if let amount = transfer.amount {
			cell.ammountLabel.text = AdamantUtilities.format(balance: amount)
		}
		
		if let date = transfer.date {
			cell.dateLabel.text = DateFormatter.localizedString(from: date as Date, dateStyle: .short, timeStyle: .medium)
		}
	}
}


// MARK: - UITableView
extension TransactionsViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let f = controller?.fetchedObjects {
			return f.count
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
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: SharedCell.TransactionCell.cellIdentifier, for: indexPath) as? TransactionTableViewCell,
			let transfer = controller?.object(at: indexPath) else {
				// TODO: Display & Log error
				return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		configureCell(cell, for: transfer)
		return cell
	}
}

extension TransactionsViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			if let newIndexPath = newIndexPath {
				tableView.insertRows(at: [newIndexPath], with: .automatic)
			}
			
		case .delete:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .automatic)
			}
			
		case .update:
			if let indexPath = indexPath,
				let cell = self.tableView.cellForRow(at: indexPath) as? TransactionTableViewCell,
				let transfer = anObject as? TransferTransaction {
				configureCell(cell, for: transfer)
			}
			
		default:
			break
		}
	}
}

