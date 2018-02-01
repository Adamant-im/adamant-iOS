//
//  ChatsListViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

class ChatsListViewController: UIViewController {
	// MARK: - Dependencies
	var accountService: AccountService!
	var chatProvider: ChatDataProvider!
	var cellFactory: CellFactory!
	var apiService: ApiService!
	var router: Router!
	
	// MARK: - IBOutlet
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var newChatButton: UIBarButtonItem!
	
	// MARK: - Properties
	let showChatSegue = "showChat"
	let newChatSegue = "newChat"
	var chatsController: NSFetchedResultsController<Chatroom>!
	let chatCell = SharedCell.ChatCell.cellIdentifier
	private var preservedMessagess = [String:String]()
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(cellFactory.nib(for: SharedCell.ChatCell), forCellReuseIdentifier: chatCell)
		
		chatsController = chatProvider.getChatroomsController()
		chatsController.delegate = self
		
		tableView.reloadData()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier else {
			return
		}
		
		switch identifier {
		case showChatSegue:
			if let chatroom = sender as? Chatroom, let vc = segue.destination as? ChatViewController,
				let account = accountService.account {
				prepareChatViewController(vc, account: account, chatroom: chatroom)
			}
			
		case newChatSegue:
			if let vc = segue.destination as? NewChatViewController {
				vc.delegate = self
			} else if let nav = segue.destination as? UINavigationController, let vc = nav.viewControllers.first as? NewChatViewController {
				vc.delegate = self
			}
			
		default:
			return
		}
	}
	
	private func prepareChatViewController(_ vc: ChatViewController, account: Account, chatroom: Chatroom) {
		vc.hidesBottomBarWhenPushed = true
		vc.chatroom = chatroom
		vc.account = account
		vc.delegate = self
	}
}


// MARK: - UITableView
extension ChatsListViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let f = chatsController.fetchedObjects {
			return f.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return SharedCell.ChatCell.defaultRowHeight
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let chatroom = chatsController.object(at: indexPath)
		performSegue(withIdentifier: showChatSegue, sender: chatroom)
	}
}


// MARK: - UITableView Cells
extension ChatsListViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let chat = chatsController.object(at: indexPath)
		let cell: ChatTableViewCell = tableView.dequeueReusableCell(withIdentifier: chatCell, for: indexPath) as! ChatTableViewCell
		
		configureCell(cell, for: chat)
		
		return cell
	}
	
	private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
		cell.accessoryType = .disclosureIndicator
		
		if let title = chatroom.title {
			cell.accountLabel.text = title
		} else {
			cell.accountLabel.text = chatroom.id
		}
		
		cell.lastMessageLabel.text = chatroom.lastTransaction?.message
		if let date = chatroom.updatedAt as Date? {
			cell.dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
		} else {
			cell.dateLabel.text = nil
		}
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension ChatsListViewController: NSFetchedResultsControllerDelegate {
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
				self.tableView.insertRows(at: [newIndexPath], with: .automatic)
			}
			
		case .delete:
			if let indexPath = indexPath {
				self.tableView.deleteRows(at: [indexPath], with: .automatic)
			}
			
		case .update:
			if let indexPath = indexPath,
				let cell = self.tableView.cellForRow(at: indexPath) as? ChatTableViewCell,
				let chatroom = controller.object(at: indexPath) as? Chatroom {
				self.configureCell(cell, for: chatroom)
			}
			
		case .move:
			if let indexPath = indexPath, let newIndexPath = newIndexPath {
				self.tableView.moveRow(at: indexPath, to: newIndexPath)
			}
		}
	}
}


// MARK: - NewChatViewControllerDelegate
extension ChatsListViewController: NewChatViewControllerDelegate {
	func newChatController(_ controller: NewChatViewController, didSelectedAddress address: String) {
		guard AdamantUtilities.validateAdamantAddress(address: address),
			let account = accountService.account else {
			// TODO: Show error
			return
		}
		
		// TODO: Show progress
		apiService.getPublicKey(byAddress: address) { (publicKey, error) in
			guard publicKey != nil else {
				// TODO: Show error
				return
			}
			
			let chatroom = self.chatProvider.newChatroom(with: address)
			
			DispatchQueue.main.async {
				if let vc = self.router.get(scene: .Chat) as? ChatViewController {
					self.prepareChatViewController(vc, account: account, chatroom: chatroom)
					self.navigationController?.pushViewController(vc, animated: false)
					
					let nvc: UIViewController
					if let nav = controller.navigationController {
						nvc = nav
					} else {
						nvc = controller
					}
					
					nvc.dismiss(animated: true) {
						vc.becomeFirstResponder()
						
						if let count = vc.chatroom?.transactions?.count, count == 0 {
							vc.messageInputBar.inputTextView.becomeFirstResponder()
						}
					}
				}
			}
			
			// Select row after awhile
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
				if let indexPath = self.chatsController.indexPath(forObject: chatroom) {
					self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
				}
			}
		}
	}
}


// MARK: - ChatViewControllerDelegate
extension ChatsListViewController: ChatViewControllerDelegate {
	func preserveMessage(_ message: String, forAddress address: String) {
		preservedMessagess[address] = message
	}
	
	func getPreservedMessageFor(address: String, thenRemoveIt: Bool) -> String? {
		guard let message = preservedMessagess[address] else {
			return nil
		}
		
		if thenRemoveIt {
			preservedMessagess.removeValue(forKey: address)
		}
		
		return message
	}
}
