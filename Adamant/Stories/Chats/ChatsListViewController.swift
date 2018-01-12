//
//  ChatsListViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class ChatsListViewController: UIViewController {
	// MARK: - Dependencies
	var loginService: AccountService!
	
	
	// MARK: - IBOutlet
	@IBOutlet weak var tableView: UITableView!
	
	
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
	}
}




// MARK: - UITableView
extension ChatsListViewController: UITableViewDelegate, UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 1
			
		case 1:	// TODO: chats
			return 0
			
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
		if indexPath.section == 0 {
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
		}
		
		return UITableViewCell(style: .subtitle, reuseIdentifier: "chat")
	}
}
