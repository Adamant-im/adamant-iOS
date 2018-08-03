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
extension String.adamantLocalized {
	struct transactionDetails {
		static let title = NSLocalizedString("TransactionDetailsScene.Title", comment: "Transaction details: scene title")
		
		static let yourAddress = NSLocalizedString("TransactionDetailsScene.YourAddress", comment: "Transaction details: 'Your address' flag.")
	}
}

extension String.adamantLocalized.alert {
	static let exportUrlButton = NSLocalizedString("TransactionDetailsScene.Share.URL", comment: "Export transaction: 'Share transaction URL' button")
	static let exportSummaryButton = NSLocalizedString("TransactionDetailsScene.Share.Summary", comment: "Export transaction: 'Share transaction summary' button")
}


// MARK: - 
class TransactionDetailsViewController: UIViewController {
	// MARK: - Rows
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
        case openChat	// if transaction.chatroom.isHidden, numberOfRowsInSection will return total-1
		
		static let total = 10
		
		var localized: String {
			switch self {
			case .transactionNumber: return NSLocalizedString("TransactionDetailsScene.Row.Id", comment: "Transaction details: Id row.")
			case .from: return NSLocalizedString("TransactionDetailsScene.Row.From", comment: "Transaction details: sender row.")
			case .to: return NSLocalizedString("TransactionDetailsScene.Row.To", comment: "Transaction details: recipient row.")
			case .date: return NSLocalizedString("TransactionDetailsScene.Row.Date", comment: "Transaction details: date row.")
			case .amount: return NSLocalizedString("TransactionDetailsScene.Row.Amount", comment: "Transaction details: amount row.")
			case .fee: return NSLocalizedString("TransactionDetailsScene.Row.Fee", comment: "Transaction details: fee row.")
			case .confirmations: return NSLocalizedString("TransactionDetailsScene.Row.Confirmations", comment: "Transaction details: confirmations row.")
			case .block: return NSLocalizedString("TransactionDetailsScene.Row.Block", comment: "Transaction details: Block id row.")
			case .openInExplorer: return NSLocalizedString("TransactionDetailsScene.Row.Explorer", comment: "Transaction details: 'Open transaction in explorer' row.")
            case .openChat: return ""
			}
		}
		
		var image: UIImage? {
			switch self {
			case .openInExplorer: return #imageLiteral(resourceName: "row_explorer")
			case .openChat: return #imageLiteral(resourceName: "row_chat")
				
			default: return nil
			}
		}
	}
	
	// MARK: - Dependencies
    var accountService: AccountService!
	var dialogService: DialogService!
    var transfersProvider: TransfersProvider!
    var router: Router!
	
	// MARK: - Properties
	private let cellIdentifier = "cell"
	private let doubleDetailsCellIdentifier = "dcell"
	private let defaultCellHeight: CGFloat = 50.0
	
	var transaction: TransferTransaction?
	var explorerUrl: URL!
    var haveChatroom = false
	var showToChatRow = true
	
	private let autoupdateInterval: TimeInterval = 5.0
    
    weak var timer: Timer?
    
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
	override func viewDidLoad() {
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = true
		}
		
		navigationItem.title = String.adamantLocalized.transactionDetails.title
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
		tableView.dataSource = self
		tableView.delegate = self
		
		tableView.register(UINib(nibName: "DoubleDetailsTableViewCell", bundle: nil), forCellReuseIdentifier: doubleDetailsCellIdentifier)
		
		if let transaction = transaction {
            if let chatroom = transaction.partner?.chatroom, let transactions = chatroom.transactions  {
                let messeges = transactions.first (where: { (object) -> Bool in
                    return !(object is TransferTransaction)
                })
                
                haveChatroom = (messeges != nil)
            }
            
			tableView.reloadData()
			
			if let id = transaction.transactionId {
				explorerUrl = URL(string: "https://explorer.adamant.im/tx/\(id)")
			}
		} else {
			self.navigationItem.rightBarButtonItems = nil
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAddressBookService.addressBookUpdated, object: nil, queue: nil) { [weak self] notification in
			guard let partner = self?.transaction?.partner?.address else {
				return
			}
			
			guard let changes = notification.userInfo?[AdamantUserInfoKey.AddressBook.changes] as? [AddressBookChange] else {
				return
			}
			
			for change in changes {
				switch change {
				case .newName(let address, _), .updated(let address, _), .removed(let address):
					if partner == address {
						if Thread.isMainThread {
							self?.tableView.reloadData()
						} else {
							DispatchQueue.main.async {
								self?.tableView.reloadData()
							}
						}
						
						return
					}
				}
			}
		}
		
        startUpdate()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	deinit {
		stopUpdate()
	}
	
	
	// MARK: - IBActions
	
	@IBAction func share(_ sender: UIBarButtonItem) {
		guard let transaction = transaction, let url = explorerUrl else {
			return
		}
		
		let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
		
		// URL
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportUrlButton, style: .default) { [weak self] _ in
			let alert = UIActivityViewController(activityItems: [url], applicationActivities: nil)
			self?.present(alert, animated: true, completion: nil)
		})
		
		// Description
		alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.exportSummaryButton, style: .default, handler: { [weak self] _ in
			let text = AdamantFormattingTools.summaryFor(transaction: transaction, url: url)
			let alert = UIActivityViewController(activityItems: [text], applicationActivities: nil)
			self?.present(alert, animated: true, completion: nil)
		}))
		alert.popoverPresentationController?.barButtonItem = sender
		present(alert, animated: true, completion: nil)
	}
	
	
	
}


// MARK: - UITableView
extension TransactionDetailsViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let transaction = transaction else {
			return 0
		}
		
		var total = Row.total
		
		if let hidden = transaction.chatroom?.isHidden, hidden {
			total -= 1
		} else if !showToChatRow {
			total -= 1
		}
		
		return total
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		guard let row = Row(rawValue: indexPath.row) else {
			return defaultCellHeight
		}
		
		switch row {
		case .from:
			if let address = accountService.account?.address, address == transaction?.senderId {
				return DoubleDetailsTableViewCell.fullHeight
			} else if let partner = transaction?.partner, partner.name != nil {
				return DoubleDetailsTableViewCell.fullHeight
			} else {
				break // return default
			}
			
		case .to:
			if let address = accountService.account?.address, address == transaction?.recipientId {
				return DoubleDetailsTableViewCell.fullHeight
			} else if let partner = transaction?.partner, partner.name != nil {
				return DoubleDetailsTableViewCell.fullHeight
			} else {
				break // return default
			}
			
		default:
			break
		}
		
		return defaultCellHeight
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let row = Row(rawValue: indexPath.row), let cell = tableView.cellForRow(at: indexPath) else {
			tableView.deselectRow(at: indexPath, animated: true)
			return
		}
		
		switch row {
		case .openInExplorer:
			if let url = explorerUrl {
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamant.primary
				present(safari, animated: true, completion: nil)
			}
			
		case .openChat:
			// TODO: Log errors
			guard let vc = self.router.get(scene: AdamantScene.Chats.chat) as? ChatViewController else {
				dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get ChatViewController", error: nil)
				break
			}
			
			guard let chatroom = transaction?.partner?.chatroom else {
				dialogService.showError(withMessage: "TransactionDetailsViewController: Failed to get chatroom for transaction.", error: nil)
				break
			}
			
			guard let account = self.accountService.account else {
				dialogService.showError(withMessage: "TransactionDetailsViewController: User not logged.", error: nil)
				break
			}
			
			vc.account = account
			vc.chatroom = chatroom
			vc.hidesBottomBarWhenPushed = true
			
			if let nav = self.navigationController {
				nav.pushViewController(vc, animated: true)
			} else {
				self.present(vc, animated: true)
			}
			
		case .to, .from:
			guard let address = row == .to ? transaction?.recipientId : transaction?.senderId else {
				tableView.deselectRow(at: indexPath, animated: true)
				break
			}
			
			let share: String
			
			if let myAddress = accountService.account?.address, myAddress == address {
				share = address
			} else if let name = transaction?.partner?.name {
				share = "\(name) (\(address))"
			} else {
				share = address
			}
			
            dialogService.presentShareAlertFor(string: share, types: [.copyToPasteboard, .share], excludedActivityTypes: nil, animated: true, from: cell) {
				tableView.deselectRow(at: indexPath, animated: true)
			}
			
		default:
			let share: String
            
			if row == .date, let date = transaction?.date as Date? {
				share = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)
			} else if let details = cell.detailTextLabel?.text {
				share = details
			} else {
				tableView.deselectRow(at: indexPath, animated: true)
				break
			}
			
            dialogService.presentShareAlertFor(string: share, types: [.copyToPasteboard, .share], excludedActivityTypes: nil, animated: true, from: cell) {
				tableView.deselectRow(at: indexPath, animated: true)
			}
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
		
		let cell: UITableViewCell
		
		switch row {
		case .to, .from:
			cell = tableView.dequeueReusableCell(withIdentifier: doubleDetailsCellIdentifier, for: indexPath)
		
		default:
			if let c = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
				cell = c
				cell.accessoryType = .none
				cell.imageView?.image = nil
			} else {
				cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
			}
			
			cell.textLabel?.text = row.localized
			cell.imageView?.image = row.image
			cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
		}
		
		switch row {
		case .amount:
			if let amount = transaction.amount {
				cell.detailTextLabel?.text = AdamantUtilities.format(balance: amount)
			}
			
		case .date:
			if let date = transaction.date as Date? {
				cell.detailTextLabel?.text = date.humanizedDateTimeFull()
			}
			
		case .confirmations:
			cell.detailTextLabel?.text = String(transaction.confirmations)
			
		case .fee:
			if let fee = transaction.fee {
				cell.detailTextLabel?.text = AdamantUtilities.format(balance: fee)
			}
			
		case .transactionNumber:
			if let id = transaction.transactionId {
				cell.detailTextLabel?.text = String(id)
			}
			
		case .from:
			guard let dCell = cell as? DoubleDetailsTableViewCell else {
				break
			}
			
			let first: String?
			let second: String?
			
			if let address = accountService.account?.address, address == transaction.senderId {
				first = String.adamantLocalized.transactionDetails.yourAddress
				second = address
			} else if let name = transaction.partner?.name {
				first = name
				second = transaction.senderId
			} else {
				first = transaction.senderId
				second = nil
			}
			
			dCell.titleLabel.text = row.localized
			dCell.detailsLabel.text = first
			dCell.secondDetailsLabel.text = second
			
		case .to:
			guard let dCell = cell as? DoubleDetailsTableViewCell else {
				break
			}
			
			let first: String?
			let second: String?
			
			if let address = accountService.account?.address, address == transaction.recipientId {
				first = String.adamantLocalized.transactionDetails.yourAddress
				second = address
			} else if let name = transaction.partner?.name {
				first = name
				second = transaction.recipientId
			} else {
				first = transaction.recipientId
				second = nil
			}
			
			dCell.titleLabel.text = row.localized
			dCell.detailsLabel.text = first
			dCell.secondDetailsLabel.text = second
			
		case .block:
			cell.detailTextLabel?.text = transaction.blockId
			
		case .openInExplorer:
			cell.detailTextLabel?.text = nil
			cell.accessoryType = .disclosureIndicator
        case .openChat:
            cell.textLabel?.text = (self.haveChatroom) ? String.adamantLocalized.transactionList.toChat : String.adamantLocalized.transactionList.startChat
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }
		
		return cell
	}
}


// MARK: - Autoupdate
extension TransactionDetailsViewController {
	func startUpdate() {
		timer?.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: autoupdateInterval, repeats: true) { [weak self] _ in
			guard let id = self?.transaction?.transactionId else {
				return
			}
			
			self?.transfersProvider.refreshTransfer(id: id) { result in
				switch result {
				case .success:
					DispatchQueue.main.async {
						self?.tableView.reloadData()
					}
					
				case .failure:
					return
				}
			}
		}
	}
	
	func stopUpdate() {
		timer?.invalidate()
	}
}
