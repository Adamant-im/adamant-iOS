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
	
	// MARK: - IBOutlet
	@IBOutlet weak var tableView: UITableView!
	
	// MARK: - Properties
	var chatsController: NSFetchedResultsController<Chatroom>!
	
	// MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.dataSource = self
		tableView.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
		
		chatsController = chatProvider.getChatroomsController()
		chatsController.delegate = self
		tableView.reloadData()
	}
}


// MARK: - UITableView
extension ChatsListViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// TODO: Magic numbers!!
		switch section {
		case 0:
			return 1
			
		case 1:
			if let f = chatsController.fetchedObjects {
				return f.count
			} else {
				return 0
			}
			
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 80
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
}


// MARK: - UITableView Cells
extension ChatsListViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			let cell: UITableViewCell
			if let c = tableView.dequeueReusableCell(withIdentifier: "action") {
				cell = c
			} else {
				cell = UITableViewCell(style: .default, reuseIdentifier: "action")
				cell.imageView?.tintColor = UIColor.adamantChatIcons
			}
			
			cell.textLabel?.text = "Start new chat"
			cell.imageView?.image = #imageLiteral(resourceName: "newChat")
			
			return cell
		
		case 1:
			guard let chat = chatsController.fetchedObjects?[indexPath.row] else {
				fatalError()
			}
			
			let cell: UITableViewCell
			if let c = tableView.dequeueReusableCell(withIdentifier: "chat") {
				cell = c
			} else {
				cell = UITableViewCell(style: .default, reuseIdentifier: "chat")
				cell.imageView?.tintColor = UIColor.adamantChatIcons
			}
			
			cell.textLabel?.text = chat.id
			
			return cell
			
		default:
			fatalError()
		}
		
		return UITableViewCell(style: .subtitle, reuseIdentifier: "chat")
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension ChatsListViewController: NSFetchedResultsControllerDelegate {
	
}
