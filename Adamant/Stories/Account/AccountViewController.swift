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
	private let cellIdentifier = "cell"
	private let showTransactionsSegue = "showTransactions"
	private let showTransferSegue = "showTransfer"
	
	private enum Rows: Int {
		case accountNumber = 0, balance, sendTokens
	}
	
	
	// MARK: - Dependencies
	var loginService: AccountService!
	var dialogService: DialogService!
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()

		tableView.delegate = self
		tableView.dataSource = self
		tableView.separatorInset = UIEdgeInsets.init(top: 0, left: 80, bottom: 0, right: 0)
		
		NotificationCenter.default.addObserver(forName: .userHasLoggedIn, object: nil, queue: nil) { _ in
			self.tableView.reloadData()
		}
		NotificationCenter.default.addObserver(forName: .userHasLoggedOut, object: nil, queue: nil) { _ in
			self.tableView.reloadData()
		}
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
		case showTransactionsSegue:
			if let account = loginService.loggedAccount?.address, let vc = segue.destination as? TransactionsViewController {
				vc.account = account
			}
			
		case showTransferSegue:
			if let account = loginService.loggedAccount, let vc = segue.destination as? TransferViewController {
				vc.account = account
			}
			
		default:
			return
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}


// MARK: - UITableViewDataSource
extension AccountViewController: UITableViewDataSource {
	
	// MARK: Configuring TableView
	
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
		return 80
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	
	// MARK: Cells
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let account = loginService.loggedAccount,
			let row = Rows(rawValue: indexPath.row) else {
			return UITableViewCell(style: .default, reuseIdentifier: nil)
		}
		
		let cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
			cell = c
		} else {
			cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
			cell.accessoryType = .disclosureIndicator
			cell.textLabel?.font = UIFont(name: "Exo 2", size: 17)
			cell.detailTextLabel?.font = UIFont(name: "Exo 2", size: 12)
			
			cell.textLabel?.textColor = UIColor.adamantPrimary
			cell.detailTextLabel?.textColor = UIColor.adamantSecondary
		}
		
		switch row {
		case .accountNumber:
			cell.textLabel?.text = "Your address"
			cell.detailTextLabel?.text = account.address
			cell.imageView?.image = #imageLiteral(resourceName: "account")
			
		case .balance:
			cell.textLabel?.text = "Your balance"
			cell.detailTextLabel?.text = AdamantFormatters.format(balance: account.balance)
			cell.imageView?.image = #imageLiteral(resourceName: "wallet")
			break
			
		case .sendTokens:
			cell.textLabel?.text = "Send tokens"
			cell.detailTextLabel?.text = nil
			cell.imageView?.image = #imageLiteral(resourceName: "send")
			break
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
			
			guard let address = self.loginService.loggedAccount?.address else {
				return
			}
			
			let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
			
			alert.addAction(UIAlertAction(title: "Copy To Pasteboard", style: .default, handler: { _ in
				UIPasteboard.general.string = address
				self.dialogService.showToastMessage("\(address)\nCopied To Pasteboard!")
			}))
			
			alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { _ in
				let vc = UIActivityViewController(activityItems: [address], applicationActivities: nil)
				self.present(vc, animated: true)
			}))
			
			alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
			
			present(alert, animated: true)
			
		case .balance:
			performSegue(withIdentifier: showTransactionsSegue, sender: nil)
			
		case .sendTokens:
			performSegue(withIdentifier: showTransferSegue, sender: nil)
		}
	}
}
