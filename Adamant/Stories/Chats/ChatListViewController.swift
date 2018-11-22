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
		static let sentMessagePrefix = NSLocalizedString("ChatListPage.SentMessageFormat", comment: "ChatList: outgoing message preview format, like 'You: %@'")
        static let syncingChats = NSLocalizedString("ChatListPage.SyncingChats", comment: "ChatList: First syncronization is in progress")
        
		private init() {}
	}
}

class ChatListViewController: UIViewController {
	let cellIdentifier = "cell"
	let cellHeight: CGFloat = 76.0
	
	// MARK: Dependencies
	var accountService: AccountService!
	var chatsProvider: ChatsProvider!
	var transfersProvider: TransfersProvider!
	var router: Router!
	var notificationsService: NotificationsService!
	var dialogService: DialogService!
	var addressBook: AddressBookService!
    
    var richMessageProviders = [String:RichMessageProvider]()
	
	// MARK: IBOutlet
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var newChatButton: UIBarButtonItem!
	
	// MARK: Properties
	var chatsController: NSFetchedResultsController<Chatroom>?
	var unreadController: NSFetchedResultsController<ChatTransaction>?
	
	private var preservedMessagess = [String:String]()
	
	let defaultAvatar = #imageLiteral(resourceName: "avatar-chat-placeholder")
	
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(self.handleRefresh(_:)),
                                 for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.adamant.primary
        
        return refreshControl
    }()
	
    // MARK: Busy indicator
    
    @IBOutlet weak var busyBackgroundView: UIView!
    @IBOutlet weak var busyIndicatorView: UIView!
    @IBOutlet weak var busyIndicatorLabel: UILabel!
    
    private(set) var isBusy: Bool = true
    
    
	// MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}

		navigationItem.title = String.adamantLocalized.chatList.title
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
															target: self,
															action: #selector(newChat))
		
		// MARK: TableView
		tableView.dataSource = self
		tableView.delegate = self
		tableView.register(UINib(nibName: "ChatTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.refreshControl = refreshControl
		
		if self.accountService.account != nil {
			initFetchedRequestControllers(provider: chatsProvider)
		}
		
		// MARK: Login/Logout
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.initFetchedRequestControllers(provider: self?.chatsProvider)
		}
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.initFetchedRequestControllers(provider: nil)
		}
        
        // MARK: Busy Indicator
        busyIndicatorLabel.text = String.adamantLocalized.chatList.syncingChats
        
        busyIndicatorView.layer.cornerRadius = 14
        busyIndicatorView.clipsToBounds = true
        
        isBusy = !chatsProvider.isInitiallySynced
        if !isBusy {
            setIsBusy(false, animated: false)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantChatsProvider.initiallySyncedChanged, object: chatsProvider, queue: OperationQueue.main) { [weak self] notification in
            if let synced = notification.userInfo?[AdamantUserInfoKey.ChatProvider.initiallySynced] as? Bool {
                self?.setIsBusy(!synced)
            } else if let synced = self?.chatsProvider.isInitiallySynced {
                self?.setIsBusy(!synced)
            } else {
                self?.setIsBusy(true)
            }
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
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
	}
	
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
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
		
        if let split = self.splitViewController {
            split.showDetailViewController(controller, sender: self)
        } else {
            present(controller, animated: true)
        }
	}
	
	
	// MARK: Helpers
	private func chatViewController(for chatroom: Chatroom) -> ChatViewController {
		guard let vc = router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
			fatalError("Can't get ChatViewController")
		}
		
		if let account = accountService.account {
			vc.account = account
		}
		
		vc.hidesBottomBarWhenPushed = true
		vc.chatroom = chatroom
		vc.delegate = self
		
		return vc
	}
	
	
	/// - Parameter provider: nil to drop controllers and reset table
	private func initFetchedRequestControllers(provider: ChatsProvider?) {
		guard let provider = provider else {
			chatsController = nil
			unreadController = nil
			tableView.reloadData()
			return
		}
		
		chatsController = provider.getChatroomsController()
		unreadController = provider.getUnreadMessagesController()
		
		chatsController?.delegate = self
		unreadController?.delegate = self
		
		do {
			try chatsController?.performFetch()
			try unreadController?.performFetch()
		} catch {
			chatsController = nil
			unreadController = nil
			print("There was an error performing fetch: \(error)")
		}
		
		tableView.reloadData()
		setBadgeValue(unreadController?.fetchedObjects?.count)
	}
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        chatsProvider.update { [weak self] (result) in
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
    
    func setIsBusy(_ busy: Bool, animated: Bool = true) {
        isBusy = busy
        
        // MARK: 0. Check if animated.
        guard animated else {
            if !busy {
                busyBackgroundView.isHidden = true
                return
            }
            
            if Thread.isMainThread {
                busyBackgroundView.isHidden = false
                busyBackgroundView.alpha = 1.0
                busyIndicatorView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            } else {
                DispatchQueue.main.async {
                    self.busyBackgroundView.isHidden = false
                    self.busyBackgroundView.alpha = 1.0
                    self.busyIndicatorView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }
            
            return
        }
        
        // MARK: 1. Prepare animation and completion
        let animations: () -> Void = {
            self.busyBackgroundView.alpha = busy ? 1.0 : 0.0
            self.busyIndicatorView.transform = busy ? CGAffineTransform(scaleX: 1.0, y: 1.0) : CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        let completion: (Bool) -> Void = { completed in
            guard completed else {
                return
            }
            
            self.busyBackgroundView.isHidden = !busy
        }
        
        // MARK: 2. Initial values
        let initialValues: () -> Void = {
            self.busyBackgroundView.alpha = busy ? 0.0 : 1.0
            self.busyIndicatorView.transform = busy ? CGAffineTransform(scaleX: 1.2, y: 1.2) : CGAffineTransform(scaleX: 1.0, y: 1.0)
            
            self.busyBackgroundView.isHidden = false
        }
        
        if Thread.isMainThread {
            initialValues()
            UIView.animate(withDuration: 0.2, animations: animations, completion: completion)
        } else {
            DispatchQueue.main.async {
                initialValues()
                UIView.animate(withDuration: 0.2, animations: animations, completion: completion)
            }
        }
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
		if let chatroom = chatsController?.object(at: indexPath) {
            let vc = chatViewController(for: chatroom)
            
            if let split = self.splitViewController {
                let chat = UINavigationController(rootViewController:vc)
                split.showDetailViewController(chat, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                present(vc, animated: true)
            }
		}
	}
}


// MARK: - UITableView Cells
extension ChatListViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ChatTableViewCell
		
		cell.accessoryType = .disclosureIndicator
		cell.accountLabel.textColor = UIColor.adamant.primary
		cell.dateLabel.textColor = UIColor.adamant.secondary
		cell.avatarImageView.tintColor = UIColor.adamant.primary
		cell.borderColor = UIColor.adamant.primary
		cell.badgeColor = UIColor.adamant.primary
		cell.borderWidth = 1
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let cell = cell as? ChatTableViewCell, let chat = chatsController?.object(at: indexPath) {
			configureCell(cell, for: chat)
		}
	}
	
	private func configureCell(_ cell: ChatTableViewCell, for chatroom: Chatroom) {
		if let partner = chatroom.partner {
			if let title = chatroom.title {
				cell.accountLabel.text = title
			} else if let name = partner.name {
				cell.accountLabel.text = name
			} else {
				cell.accountLabel.text = partner.address
			}
			
			if let avatarName = partner.avatar, let avatar = UIImage.init(named: avatarName) {
				cell.avatarImage = avatar
				cell.avatarImageView.tintColor = UIColor.adamant.primary
			} else {
				cell.avatarImage = nil
			}
		} else if let title = chatroom.title {
			cell.accountLabel.text = title
		}
		
		cell.hasUnreadMessages = chatroom.hasUnreadMessages
        
        if let lastTransaction = chatroom.lastTransaction {
            cell.lastMessageLabel.text = shortDescription(for: lastTransaction)
        } else {
            cell.lastMessageLabel.text = nil
        }
		
		if let date = chatroom.updatedAt as Date?, date != Date.adamantNullDate {
			cell.dateLabel.text = date.humanizedDay()
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
		switch controller {
		// MARK: Chats controller
		case let c where c == chatsController:
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
			
		// MARK: Unread controller
		case let c where c == unreadController:
			guard type == .insert else {
				break
			}
			
			if let transaction = anObject as? ChatTransaction {
				showNotification(for: transaction)
			}
			
		default:
			break
		}
	}
}


// MARK: - NewChatViewControllerDelegate
extension ChatListViewController: NewChatViewControllerDelegate {
	func newChatController(_ controller: NewChatViewController, didSelectAccount account: CoreDataAccount) {
		guard let chatroom = account.chatroom else {
			fatalError("No chatroom?")
		}
		
		DispatchQueue.main.async { [weak self] in
            guard let vc = self?.chatViewController(for: chatroom) else {
                return
            }
            
            if let split = self?.splitViewController {
                let chat = UINavigationController(rootViewController:vc)
                split.showDetailViewController(chat, sender: self)
            } else {
                self?.navigationController?.pushViewController(vc, animated: false)
            }

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


// MARK: - Working with in-app notifications
extension ChatListViewController {
	private func showNotification(for transaction: ChatTransaction) {
        // MARK: 0. Do not show notifications for initial sync
        guard chatsProvider.isInitiallySynced else {
            return
        }
        
		// MARK: 1. Show notification only for incomming transactions
		guard !transaction.silentNotification, !transaction.isOutgoing,
			let chatroom = transaction.chatroom, chatroom != presentedChatroom(), !chatroom.isHidden,
			let partner = chatroom.partner else {
			return
		}
		
        // MARK: 2. Prepare notification
        let title = partner.name ?? partner.address
        let text = shortDescription(for: transaction)
		
		let image: UIImage
		if let ava = partner.avatar, let img = UIImage(named: ava) {
			image = img
		} else {
			image = defaultAvatar
		}
		
		// MARK: 4. Show notification with tap handler
		dialogService.showNotification(title: title, message: text, image: image) { [weak self] in
			DispatchQueue.main.async {
				self?.presentChatroom(chatroom)
			}
		}
	}
	
	private func presentChatroom(_ chatroom: Chatroom) {
		// MARK: 1. Create and config ViewController
        let vc = chatViewController(for: chatroom)
        
        if let split = self.splitViewController {
            let chat = UINavigationController(rootViewController:vc)
            split.showDetailViewController(chat, sender: self)
        } else {
            // MARK: 2. Config TabBarController
            let animated: Bool
            if let tabVC = tabBarController, let selectedView = tabVC.selectedViewController {
                if let navigator = navigationController, selectedView != navigator, let index = tabVC.viewControllers?.index(of: navigator) {
                    animated = false
                    tabVC.selectedIndex = index
                } else {
                    animated = true
                }
            } else {
                animated = true
            }
            
            
            // MARK: 3. Present ViewController
            if let nav = navigationController {
                nav.pushViewController(vc, animated: animated)
            } else {
                present(vc, animated: true)
            }
        }
	}
    
    private func shortDescription(for transaction: ChatTransaction) -> String? {
        switch transaction {
        case let message as MessageTransaction:
            guard let text = message.message else {
                return nil
            }
            
            if message.isOutgoing {
                return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, text)
            } else {
                return text
            }
            
        case let transfer as TransferTransaction:
            if let admService = richMessageProviders[AdmWalletService.richMessageType] as? AdmWalletService {
                return admService.shortDescription(for: transfer)
            } else {
                return nil
            }
            
        case let richMessage as RichMessageTransaction:
            let description: String
            
            if let type = richMessage.richType, let provider = richMessageProviders[type] {
                description = provider.shortDescription(for: richMessage)
            } else if let serialized = richMessage.serializedMessage() {
                description = serialized
            } else {
                return nil
            }
            
            if richMessage.isOutgoing {
                return String.localizedStringWithFormat(String.adamantLocalized.chatList.sentMessagePrefix, description)
            } else {
                return description
            }
            
        default:
            return nil
        }
    }
}


// MARK: - Swipe actions
extension ChatListViewController {
	@available(iOS 11.0, *)
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		guard let chatroom = chatsController?.object(at: indexPath) else {
			return nil
		}
		
		let actions: [UIContextualAction]
		
		// More
		let more = UIContextualAction(style: .normal, title: nil) { [weak self] (_, view, completionHandler: (Bool) -> Void) in
			guard let partner = chatroom.partner, let address = partner.address else {
				completionHandler(false)
				return
			}
			
			let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
			
			if partner.isSystem {
				self?.dialogService.presentShareAlertFor(string: address,
                                                         types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address)],
                                                         excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                         animated: true, from: view,
                                                         completion: nil)
			} else {
				let share = UIAlertAction(title: ShareType.share.localized, style: .default) { [weak self] action in
					self?.dialogService.presentShareAlertFor(string: address,
															 types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address)],
															 excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                             animated: true, from: view,
															 completion: nil)
				}
				
				let rename = UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak self] action in
					let alert = UIAlertController(title: String(format: String.adamantLocalized.chat.actionsBody, address), message: nil, preferredStyle: .alert)
					
					alert.addTextField { (textField) in
						textField.placeholder = String.adamantLocalized.chat.name
						textField.autocapitalizationType = .words
						
						if let name = partner.name {
							textField.text = name
						}
					}
					 
					alert.addAction(UIAlertAction(title: String.adamantLocalized.chat.rename, style: .default) { [weak alert] (_) in
						if let textField = alert?.textFields?.first, let newName = textField.text {
							self?.addressBook.set(name: newName, for: address)
						}
					})
					
					alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
					
					self?.present(alert, animated: true, completion: nil)
				}
				
                let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil)
                
                self?.dialogService?.showAlert(title: nil, message: nil, style: UIAlertController.Style.actionSheet, actions: [share, rename, cancel], from: view)
			}
			
			completionHandler(true)
		}
		
		more.image = #imageLiteral(resourceName: "swipe_more")
		more.backgroundColor = UIColor.adamant.primary
		
		// Mark as read
		if chatroom.hasUnreadMessages {
			let markAsRead = UIContextualAction(style: .normal, title: nil) { [weak self] (_, _, completionHandler: (Bool) -> Void) in
				guard let chatroom = self?.chatsController?.object(at: indexPath) else {
					completionHandler(false)
					return
				}
				
				chatroom.markAsReaded()
				try? chatroom.managedObjectContext?.save()
				completionHandler(true)
			}
			
			markAsRead.image = #imageLiteral(resourceName: "swipe_mark-as-read")
			markAsRead.backgroundColor = UIColor.adamant.primary
			
			actions = [markAsRead, more]
		} else {
			actions = [more]
		}
		
		return UISwipeActionsConfiguration(actions: actions)
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
			notificationsService.setBadge(number: value)
		} else {
			item.badgeValue = nil
			notificationsService.setBadge(number: nil)
		}
	}
	
	/// Current chat
	func presentedChatroom() -> Chatroom? {
		guard let vc = navigationController?.visibleViewController as? ChatViewController else {
			return nil
		}
		
		return vc.chatroom
	}
}
