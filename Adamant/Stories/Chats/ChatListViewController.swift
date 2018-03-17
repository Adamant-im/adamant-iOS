//
//  ChatListViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import CoreData

extension String.adamantLocalized {
	struct chatList {
		static let title = NSLocalizedString("ChatListPage.Title", comment: "ChatList: scene title")
		
		private init() {}
	}
}

class ChatListViewController: UIViewController {
	let cellIdentifier = "cell"
	let cellHeight: CGFloat = 74.0
	
	// MARK: Dependencies
	var accountService: AccountService!
	var chatsProvider: ChatsProvider!
	var router: Router!
	
	// MARK: IBOutlet
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var newChatButton: UIBarButtonItem!
	
	// MARK: Properties
	var chatsController: NSFetchedResultsController<Chatroom>?
	var unreadController: NSFetchedResultsController<ChatTransaction>?
	
	private var preservedMessagess = [String:String]()
	
	
	// MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.chatList.title
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
		
		// MARK: TableView
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
		
		chatsController = chatsProvider.getChatroomsController()
		chatsController?.delegate = self
		unreadController = chatsProvider.getUnreadMessagesController()
		unreadController?.delegate = self
		
		tableView.reloadData()
		
		// MARK: Login/Logout
		NotificationCenter.default.addObserver(forName: .adamantUserLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			guard let controller = self?.chatsProvider.getChatroomsController() else {
				return
			}
			
			controller.delegate = self
			self?.chatsController = controller
			self?.tableView.reloadData()
		}
		NotificationCenter.default.addObserver(forName: .adamantUserLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.setBadgeValue(nil)
			self?.chatsController = nil
			self?.tableView.reloadData()
		}
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	
	// MARK: IB Actions
	@IBAction func newChat(sender: Any) {
		let controller = router.get(scene: AdamantScene.Chats.newChat)
		
		if let c = controller as? NewChatViewController {
			c.delegate = self
		} else if let nav = controller as? UINavigationController, let c = nav.viewControllers.last as? NewChatViewController {
			c.delegate = self
		}
		
		present(controller, animated: true, completion: nil)
	}
	
	
	// MARK: Helpers
	private func prepareChatViewController(_ vc: ChatViewController, chatroom: Chatroom) {
		if let account = accountService.account {
			vc.account = account
		}
		
		vc.hidesBottomBarWhenPushed = true
		vc.chatroom = chatroom
		vc.delegate = self
	}
}


// MARK: - UITableView
extension ChatListViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let f = chatsController?.fetchedObjects {
			return f.count
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return cellHeight
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let chatroom = chatsController?.object(at: indexPath), let c = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController {
			prepareChatViewController(c, chatroom: chatroom)
			
			if let nav = navigationController {
				nav.pushViewController(c, animated: true)
			} else {
				present(c, animated: true)
			}
		}
	}
}


// MARK: - UITableView Cells
extension ChatListViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
		
		cell.accessoryType = .disclosureIndicator
		cell.accountLabel.textColor = UIColor.adamantPrimary
		cell.dateLabel.textColor = UIColor.adamantSecondary
		cell.avatarImageView.tintColor = UIColor.adamantChatIcons
		cell.borderColor = UIColor.adamantPrimary
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let chatCell = cell as? ChatTableViewCell, let chat = chatsController?.object(at: indexPath) {
			chatCell.badgeColor = UIColor.adamantPrimary
			configureCell(chatCell, for: chat)
		}
	}
	
	private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
		if let partner = chatroom.partner {
			if let name = partner.name {
				cell.accountLabel.text = name
			} else {
				cell.accountLabel.text = partner.address
			}
			
			if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
				cell.avatarImage = avatar
				cell.avatarImageView.tintColor = UIColor.adamantPrimary
				cell.borderWidth = 1
			} else {
				cell.avatarImage = nil
				cell.borderWidth = 0
			}
		}
		
		cell.hasUnreadMessages = chatroom.hasUnreadMessages
		cell.lastMessageLabel.text = chatroom.lastTransaction?.message
		
		if let date = chatroom.updatedAt as Date? {
			cell.dateLabel.text = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
		} else {
			cell.dateLabel.text = nil
		}
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension ChatListViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		if controller == chatsController {
			tableView.beginUpdates()
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		switch controller {
		case let c where c == chatsController:
			tableView.endUpdates()
			
		case let c where c == unreadController:
			setBadgeValue(controller.fetchedObjects?.count)
			
		default:
			break
		}
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		
		guard controller == chatsController else {
			return
		}
		
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
				let cell = self.tableView.cellForRow(at: indexPath) as? ChatTableViewCell,
				let chatroom = anObject as? Chatroom {
				configureCell(cell, for: chatroom)
			}
			
		case .move:
			if let indexPath = indexPath, let newIndexPath = newIndexPath {
				if let cell = tableView.cellForRow(at: indexPath) as? ChatTableViewCell, let chatroom = anObject as? Chatroom {
					configureCell(cell, for: chatroom)
				}
				tableView.moveRow(at: indexPath, to: newIndexPath)
			}
		}
	}
}


// MARK: - NewChatViewControllerDelegate
extension ChatListViewController: NewChatViewControllerDelegate {
	func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount) {
		let chatroom = self.chatsProvider.chatroomWith(account)
		
		DispatchQueue.main.async {
			if let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController {
				self.prepareChatViewController(vc, chatroom: chatroom)
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
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) { [weak self] in
			if let indexPath = self?.chatsController?.indexPath(forObject: chatroom) {
				self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
			}
		}
	}
}


// MARK: - ChatViewControllerDelegate
extension ChatListViewController: ChatViewControllerDelegate {
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


// MARK: - Tools
extension ChatListViewController {
	/// TabBar item badge
	func setBadgeValue(_ value: Int?) {
		let item: UITabBarItem
		if let i = navigationController?.tabBarItem {
			item = i
		} else {
			item = tabBarItem
		}
		
		if let value = value, value > 0 {
			item.badgeValue = String(value)
		} else {
			item.badgeValue = nil
		}
	}
	
	/// Current chat
	func presentedChatroom() -> Chatroom? {
		// Showing another page
		guard tabBarController?.selectedViewController == self else {
			return nil
		}
		
		// Showing list of chats
		guard var vc = presentedViewController else {
			return nil
		}
		
		while vc != self {
			if let ch = vc as? ChatViewController {
				return ch.chatroom
			}
			
			if let v = vc.presentingViewController {
				vc = v
			} else {
				return nil
			}
		}

		return nil
	}
}
