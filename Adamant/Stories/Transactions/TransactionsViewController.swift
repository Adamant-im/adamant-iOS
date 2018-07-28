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
        static let toChat = NSLocalizedString("TransactionListScene.ToChat", comment: "TransactionList: To Chat button")
        static let startChat = NSLocalizedString("TransactionListScene.StartChat", comment: "TransactionList: Start Chat button")
	}
}

class TransactionsViewController: UIViewController {
	let cellIdentifierFull = "cf"
	let cellIdentifierCompact = "cc"
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var transfersProvider: TransfersProvider!
	var dialogService: DialogService!
	var stack: CoreDataStack!
	var router: Router!
	
	// MARK: - Properties
	var controller: NSFetchedResultsController<TransferTransaction>?
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamant.primary
        
        return refreshControl
    }()
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
		
		navigationItem.title = String.adamantLocalized.transactionList.title
		
		if accountService.account != nil {
			initFetchedResultController(provider: transfersProvider)
		}
		
		tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifierFull)
		tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifierCompact)
		tableView.dataSource = self
		tableView.delegate = self
        tableView.refreshControl = refreshControl
		
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
		
		if tableView.isEditing {
			tableView.setEditing(false, animated: false)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// TransactionDetails can reset this setting
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
		
		markTransfersAsRead()
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
        self.transfersProvider.update { [weak self] (result) in
            guard let result = result else {
                DispatchQueue.main.async {
                    refreshControl.endRefreshing()
                }
                return
            }
            
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                break
            case .failure(let error):
				self?.dialogService.showRichError(error: error)
            }
            
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
	
	private func markTransfersAsRead() {
		let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		privateContext.parent = stack.container.viewContext
		
		let request = NSFetchRequest<TransferTransaction>(entityName: TransferTransaction.entityName)
		request.predicate = NSPredicate(format: "isUnread == true")
		request.sortDescriptors = [NSSortDescriptor(key: "transactionId", ascending: false)]
		
		if let result = try? privateContext.fetch(request) {
			result.forEach { $0.isUnread = false }
			
			if privateContext.hasChanges {
				try? privateContext.save()
			}
		}
	}
}

// MARK: - UITableView Cells
extension TransactionsViewController {
	private func configureCell(_ cell: TransactionTableViewCell, for transfer: TransferTransaction) {
		cell.accountLabel.tintColor = UIColor.adamant.primary
		cell.ammountLabel.tintColor = UIColor.adamant.primary
		cell.dateLabel.tintColor = UIColor.adamant.secondary
		cell.topImageView.tintColor = UIColor.black
		
		if transfer.isOutgoing {
			cell.transactionType = .outcome
		} else {
			cell.transactionType = .income
		}
		
		if let partner = transfer.chatroom?.partner, let name = partner.name {
			cell.accountLabel.text = name
			cell.addressLabel.text = partner.address
			
			if cell.addressLabel.isHidden {
				cell.addressLabel.isHidden = false
			}
		} else if transfer.isOutgoing {
			cell.accountLabel.text = transfer.recipientId
			
			if !cell.addressLabel.isHidden {
				cell.addressLabel.isHidden = true
			}
		} else {
			cell.accountLabel.text = transfer.senderId
			
			if !cell.addressLabel.isHidden {
				cell.addressLabel.isHidden = true
			}
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
		if let transfer = controller?.object(at: indexPath), transfer.chatroom?.partner?.name != nil {
			return TransactionTableViewCell.cellHeightFull
		} else {
			return TransactionTableViewCell.cellHeightCompact
		}
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
		guard let transfer = controller?.object(at: indexPath) else {
			return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		let identifier = transfer.chatroom?.partner?.name != nil ? cellIdentifierFull : cellIdentifierCompact
		
		guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? TransactionTableViewCell else {
				// TODO: Display & Log error
				return UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		cell.accessoryType = .disclosureIndicator
		
		configureCell(cell, for: transfer)
		return cell
	}
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        guard let transfer = controller?.object(at: editActionsForRowAt), let chatroom = transfer.partner?.chatroom, let transactions = chatroom.transactions  else {
			return nil
        }
        
        let messeges = transactions.first (where: { (object) -> Bool in
            return !(object is TransferTransaction)
        })
        
        let title = (messeges != nil) ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
        
        let toChat = UITableViewRowAction(style: .normal, title: title) { action, index in
            guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
				fatalError("Failed to get ChatViewController")
            }
			
			guard let account = self.accountService.account else {
				return
			}
			
			vc.account = account
            vc.chatroom = chatroom
			vc.hidesBottomBarWhenPushed = true
            
            if let nav = self.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self.present(vc, animated: true)
            }
        }
        
        toChat.backgroundColor = UIColor.adamant.primary
        
        return [toChat]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let transfer = controller?.object(at: indexPath), let chatroom = transfer.partner?.chatroom else {
            return nil
        }

        let title = String.adamantLocalized.transactionList.toChat

        let toChat = UIContextualAction(style: .normal, title:  title) { [weak self] (ac: UIContextualAction, view: UIView, completionHandler: (Bool) -> Void) in
			guard let vc = self?.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
				fatalError("Failed to get ChatViewController")
			}
			
			guard let account = self?.accountService.account else {
				completionHandler(false)
				return
			}
			
			vc.account = account
			vc.chatroom = chatroom
			vc.hidesBottomBarWhenPushed = true
			
			if let nav = self?.navigationController {
				nav.pushViewController(vc, animated: true)
			} else {
				self?.present(vc, animated: true)
			}
			
			completionHandler(true)
        }

        toChat.image = #imageLiteral(resourceName: "chats_tab")
        toChat.backgroundColor = UIColor.adamant.primary
		
        return UISwipeActionsConfiguration(actions: [toChat])
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


