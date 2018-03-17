//
//  AccountViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices


// MARK: - Localization
extension String.adamantLocalized {
	struct account {
		static let title = NSLocalizedString("AccountTab.Title", comment: "Account page: scene title")
		
		static let rowBalance = NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
		static let rowSendTokens = NSLocalizedString("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
		static let rowInvest = NSLocalizedString("AccountTab.Row.JoinIco", comment: "Account tab: 'Invest in ICO' button")
		static let rowLogout = NSLocalizedString("AccountTab.Row.Logout", comment: "Account tab: 'Logout' button")
		
		static let sorryAlert = NSLocalizedString("AccountTab.TransferBlocked.Title", comment: "Account tab: 'Transfer not allowed' alert title")
		static let webApp = NSLocalizedString("AccountTab.TransferBlocked.GoToPWA", comment: "Account tab: 'Transfer not allowed' alert 'go to WebApp button'")
		static let transferNotAllowed = NSLocalizedString("AccountTab.TransferBlocked.Message", comment: "Account tab: Inform user that sending tokens not allowed by Apple until the end of ICO")
		
		static let sectionAccount = NSLocalizedString("AccountTab.Section.Account", comment: "Account tab: Account section title.")
		static let sectionWallet = NSLocalizedString("AccountTab.Section.Wallet", comment: "Account tab: Wallet section title")
		static let sectionActions = NSLocalizedString("AccountTab.Section.Actions", comment: "Account tab: Actions section title")
		
		private init() { }
	}
}

fileprivate extension String.adamantLocalized.alert {
	static let logoutMessageFormat = NSLocalizedString("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
	static let logoutButton = NSLocalizedString("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
}


// MARK: -
class AccountViewController: UIViewController {
	// MARK: - Constants
	private let cellIdentifier = "cell"
	
	private let webAppUrl = URL.init(string: "https://msg.adamant.im")
	
	private enum Sections: Int {
		case account = 0, wallet, actions
		
		static let total = 3
	}
	
	private enum WalletRows: Int {
		case balance, sendTokens, invest
		
		static let total = 3
	}
	
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var router: Router!
	
	
	// MARK: - IBOutlets
	@IBOutlet weak var tableView: UITableView!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.account.title

		tableView.delegate = self
		tableView.dataSource = self
		
		NotificationCenter.default.addObserver(forName: .adamantUserLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.tableView.reloadData()
		}
		NotificationCenter.default.addObserver(forName: .adamantUserLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.tableView.reloadData()
		}
		NotificationCenter.default.addObserver(forName: .adamantAccountDataUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
			guard let account = self?.accountService.account,
				let cell = self?.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) else  {
				return
			}
			
			cell.detailTextLabel?.text = AdamantUtilities.format(balance: account.balance)
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantAccountDataUpdated, object: nil, queue: OperationQueue.main) { _ in
			self.refreshBalanceCell()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}


// MARK: - UITableView
extension AccountViewController: UITableViewDataSource, UITableViewDelegate {
	func numberOfSections(in tableView: UITableView) -> Int {
		if accountService.account != nil {
			return Sections.total
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if accountService.account != nil, let sect = Sections(rawValue: section) {
			switch sect {
			case .account: return 1
			case .wallet: return WalletRows.total
			case .actions: return 1
			}
		} else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		
		if indexPath.section == 0 && indexPath.row == 0 {
			return 65
		}
		
		return 44.5
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		return UIView()
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let section = Sections(rawValue: indexPath.section) else {
			return
		}
		
		switch section {
		case .account:
			tableView.deselectRow(at: indexPath, animated: true)
			
			guard let address = self.accountService.account?.address else {
				return
			}
			
			let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
			
			dialogService.presentShareAlertFor(string: encodedAddress,
				types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
											   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
											   animated: true,
											   completion: nil)
			
		case .wallet:
			guard let row = WalletRows(rawValue: indexPath.row) else {
				return
				
			}
			
			switch row {
			case .balance:
				let vc = router.get(scene: AdamantScene.Transactions.transactions)
				navigationController?.pushViewController(vc, animated: true)
				
			case .sendTokens:
				// <Sending funds not allowed>
				let alert = UIAlertController(title: String.adamantLocalized.account.sorryAlert, message: String.adamantLocalized.account.transferNotAllowed, preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel, handler: nil))
				
				if let url = self.webAppUrl {
					alert.addAction(UIAlertAction(title: String.adamantLocalized.account.webApp, style: .default, handler: { [weak self] _ in
						let safari  = SFSafariViewController(url: url)
						safari.preferredControlTintColor = UIColor.adamantPrimary
						self?.present(safari, animated: true, completion: nil)
					}))
				}
				
				present(alert, animated: true, completion: { [weak self] in
					self?.tableView.deselectRow(at: indexPath, animated: true)
				})
				// </Sending funds not allowed>
				
			case .invest:
				guard let address = accountService.account?.address,
					let url = URL(string: "https://adamant.im/ico/?wallet=\(address)") else {
					return
				}
				
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamantPrimary
				present(safari, animated: true, completion: nil)
				return
			}
			
		case .actions:
			guard let address = accountService.account?.address else {
				return
			}
			
			let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.logoutMessageFormat, address), message: nil, preferredStyle: .alert)
			let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel) { [weak self] _ in
				self?.tableView.deselectRow(at: indexPath, animated: true)
			}
			let logout = UIAlertAction(title: String.adamantLocalized.alert.logoutButton, style: .default) { [weak self] _ in
				self?.accountService.logout()
				if let vc = self?.router.get(scene: AdamantScene.Login.login) {
					self?.dialogService.present(vc, animated: true, completion: nil)
				}
			}
			
			alert.addAction(cancel)
			alert.addAction(logout)
			present(alert, animated: true, completion: nil)
		}
	}
}


// MARK: - UITableView Cells
extension AccountViewController {
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let account = accountService.account,
			let section = Sections(rawValue: indexPath.section) else {
				return UITableViewCell(style: .default, reuseIdentifier: nil)
		}
		
		let cell: UITableViewCell
		if let c = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
			cell = c
		} else {
			cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
			cell.accessoryType = .disclosureIndicator
			cell.textLabel?.font = UIFont.adamantPrimary(size: 17)
			cell.detailTextLabel?.font = UIFont.adamantPrimary(size: 17)
			
			cell.textLabel?.textColor = UIColor.adamantPrimary
			cell.detailTextLabel?.textColor = UIColor.adamantPrimary
			
			cell.imageView?.tintColor = UIColor.adamantChatIcons
		}
		
		switch section {
		case .account:
			cell.textLabel?.text = account.address
			cell.detailTextLabel?.text = nil
			cell.imageView?.image = #imageLiteral(resourceName: "account")
			
		case .wallet:
			guard let row = WalletRows(rawValue: indexPath.row) else {
				break
			}
			
			switch row {
			case .balance:
				cell.textLabel?.text = String.adamantLocalized.account.rowBalance
				cell.detailTextLabel?.text = AdamantUtilities.format(balance: account.balance)
				cell.imageView?.image = nil
				
			case .sendTokens:
				cell.textLabel?.text = String.adamantLocalized.account.rowSendTokens
				cell.detailTextLabel?.text = nil
				cell.imageView?.image = nil
				
			case .invest:
				cell.textLabel?.text = String.adamantLocalized.account.rowInvest
				cell.detailTextLabel?.text = nil
				cell.imageView?.image = nil
			}
			
		case .actions:
			cell.textLabel?.text = String.adamantLocalized.account.rowLogout
			cell.detailTextLabel?.text = nil
			cell.imageView?.image = nil
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		guard let sect = Sections(rawValue: section) else {
			return nil
		}
		
		switch sect {
		case .account:
			return String.adamantLocalized.account.sectionAccount
			
		case .wallet:
			return String.adamantLocalized.account.sectionWallet
			
		case .actions:
			return String.adamantLocalized.account.sectionActions
		}
	}
	
	private func refreshBalanceCell() {
		guard let account = accountService.account,
			let cell = tableView.cellForRow(at: IndexPath(row: WalletRows.balance.rawValue, section: Sections.wallet.rawValue)) else {
			return
		}
		
		cell.detailTextLabel?.text = AdamantUtilities.format(balance: account.balance)
	}
}
