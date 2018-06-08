//
//  TransactionsViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

extension String.adamantLocalized {
	struct transactionList {
		static let title = NSLocalizedString("TransactionListScene.Title", comment: "TransactionList: scene title")
	}
}

class TransactionsViewController: UIViewController {
	let cellIdentifier = "cell"
	let cellHeight: CGFloat = 90.0
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var transfersProvider: TransfersProvider!
	var router: Router!
	
	// MARK: - Properties
	var controller: NSFetchedResultsController<TransferTransaction>?
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamantPrimary
        
        return refreshControl
    }()
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.transactionList.title
		
		if accountService.account != nil {
			initFetchedResultController(provider: transfersProvider)
		}
		
		tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
		tableView.dataSource = self
		tableView.delegate = self
        tableView.addSubview(self.refreshControl)
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] notification in
			self?.initFetchedResultController(provider: self?.transfersProvider)
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.initFetchedResultController(provider: nil)
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	
	/// - Parameter provider: nil to drop and reset
	private func initFetchedResultController(provider: TransfersProvider?) {
		controller = transfersProvider.transfersController()
		controller?.delegate = self
		
		do {
			try controller?.performFetch()
		} catch {
			print("There was an error performing fetch: \(error)")
			controller = nil
		}
		
		tableView.reloadData()
	}
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.transfersProvider.forceUpdate { (result) in
            guard let result = result else {
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
                return
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                break
            case .error(let error):
                print("Error update transfers: \(error)")
            }
            
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
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
		
		if let date = transfer.date as Date? {
			cell.dateLabel.text = date.humanizedDateTime()
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
		return cellHeight
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let transaction = controller?.object(at: indexPath) else {
			tableView.deselectRow(at: indexPath, animated: true)
			return
		}
		
		guard let controller = router.get(scene: AdamantScene.Transactions.transactionDetails) as? TransactionDetailsViewController else {
			return
		}
		
		controller.transaction = transaction
		navigationController?.pushViewController(controller, animated: true)
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransactionTableViewCell,
			let transfer = controller?.object(at: indexPath) else {
				// TODO: Display & Log error
				return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		cell.accessoryType = .disclosureIndicator
		
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
				
				if let transfer = anObject as? TransferTransaction {
					transfer.isUnread = false
				}
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

