//
//  AccountViewController.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {
	// MARK: - Constants
	private enum Rows: Int {
		case accountNumber = 0, balance, sendTokens
	}
	
	
	// MARK: - Dependencies
	var loginService: LoginService!
	var cellFactory: CellFactory!
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Properties
	var roundAvatarCellIdentifier: String!
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

		tableView.delegate = self
		tableView.dataSource = self
		
		roundAvatarCellIdentifier = SharedCell.RoundAvatar.cellIdentifier
		tableView.register(cellFactory.nib(for: .RoundAvatar), forCellReuseIdentifier: roundAvatarCellIdentifier)
		
		NotificationCenter.default.addObserver(forName: .userHasLoggedIn, object: nil, queue: nil) { _ in
			self.tableView.reloadData()
		}
		NotificationCenter.default.addObserver(forName: .userHasLoggedOut, object: nil, queue: nil) { _ in
			self.tableView.reloadData()
		}
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}


// MARK: - UITableViewDataSource
extension AccountViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if loginService.loggedAccount != nil {
			return 3
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return SharedCell.RoundAvatar.defaultRowHeight
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let account = loginService.loggedAccount,
			let row = Rows(rawValue: indexPath.row),
			let cell = tableView.dequeueReusableCell(withIdentifier: roundAvatarCellIdentifier, for: indexPath) as? RoundAvatarTableViewCell else {
			return UITableViewCell(style: .default, reuseIdentifier: nil)
		}
		
		switch row {
		case .accountNumber:
			cell.mainText = "Your address"
			cell.detailsText = account.address
			
		case .balance:
			cell.mainText = "Your balance"
			cell.detailsText = AdamantFormatters.format(balance: account.balance)
			cell.accessoryType = .disclosureIndicator
			
		case .sendTokens:
			cell.mainText = "Send tokens"
			cell.detailsText = nil
			cell.accessoryType = .disclosureIndicator
		}
		
		return cell
	}
}


// MARK: - UITableViewDelegate
extension AccountViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let row = Rows(rawValue: indexPath.row) else {
			return
		}
		
		switch row {
		case .accountNumber:
			tableView.deselectRow(at: indexPath, animated: true)
			// TODO: copy to buffer
			// TODO: show notification
			
		case .balance:
			tableView.deselectRow(at: indexPath, animated: true)
			// TODO: goto transactions
			
		case .sendTokens:
			tableView.deselectRow(at: indexPath, animated: true)
			// TODO: goto send tokens
		}
	}
}
