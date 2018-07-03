//
//  WalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices
import Eureka


// MARK: - Localization
extension String.adamantLocalized {
	struct account {
		static let title = NSLocalizedString("AccountTab.Title", comment: "Account page: scene title")
		
		static let sorryAlert = NSLocalizedString("AccountTab.TransferBlocked.Title", comment: "Account tab: 'Transfer not allowed' alert title")
		static let webApp = NSLocalizedString("AccountTab.TransferBlocked.GoToPWA", comment: "Account tab: 'Transfer not allowed' alert 'go to WebApp button'")
		static let transferNotAllowed = NSLocalizedString("AccountTab.TransferBlocked.Message", comment: "Account tab: Inform user that sending tokens not allowed by Apple until the end of ICO")
		
		// URLs
		static let joinIcoUrlFormat = NSLocalizedString("AccountTab.JoinIco.UrlFormat", comment: "Account tab: A full 'Join ICO' link, with %@ as address")
		static let getFreeTokensUrlFormat = NSLocalizedString("AccountTab.FreeTokens.UrlFormat", comment: "Account atb: A full 'Get free tokens' link, with %@ as address")
		
		// Errors
		static let failedToUpdate = NSLocalizedString("AccountTab.Error.FailedToUpdateAccountFormat", comment: "Account tab: Failed to update account message. %@ for error message")
		
		private init() { }
	}
}

extension String.adamantLocalized.alert {
	static let logoutMessageFormat = NSLocalizedString("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
	static let logoutButton = NSLocalizedString("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
}


// MARK: -
class WalletViewController: FormViewController {
	// MARK: - Constants
	private let webAppUrl = URL.init(string: "https://msg.adamant.im")
	
	
	// MARK: - Rows & Sections
	private enum Sections {
		case account
		case wallet
		case actions
		
		var localized: String {
			switch self {
			case .account:
				return NSLocalizedString("AccountTab.Section.Account", comment: "Account tab: Account section title.")
				
			case .wallet:
				return NSLocalizedString("AccountTab.Section.Wallet", comment: "Account tab: Wallet section title")
				
			case .actions:
				return NSLocalizedString("AccountTab.Section.Actions", comment: "Account tab: Actions section title")
			}
		}
	}
	
	private enum Rows {
		case account
		case balance
		case sendTokens
		case invest
		case logout
		case freeTokens
		
		var tag: String {
			switch self {
			case .account:
				return "acc"
				
			case .balance:
				return "balance"
				
			case .sendTokens:
				return "sendTokens"
				
			case .invest:
				return "invest"
				
			case .logout:
				return "logout"
				
			case .freeTokens:
				return "frrtkns"
			}
		}
		
		var localized: String {
			switch self {
			case .account:
				return ""
				
			case .balance:
				return NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
				
			case .sendTokens:
				return NSLocalizedString("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
				
			case .invest:
				return NSLocalizedString("AccountTab.Row.JoinIco", comment: "Account tab: 'Join the ICO' button")
				
			case .logout:
				return NSLocalizedString("AccountTab.Row.Logout", comment: "Account tab: 'Logout' button")
				
			case .freeTokens:
				return NSLocalizedString("AccountTab.Row.FreeTokens", comment: "Account tab: 'Get free tokens' button")
			}
		}
	}
	
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var router: Router!
	
	
	// MARK: - Properties
	var hideFreeTokensRow = false
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(WalletViewController.handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = UIColor.adamantPrimary
        
        return refreshControl
    }()
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		navigationItem.title = String.adamantLocalized.account.title
		navigationOptions = .Disabled
        
        self.tableView.addSubview(self.refreshControl)
		
		// MARK: Account Section
		form +++ Section(Sections.account.localized)
			
			<<< AccountRow() {
				$0.tag = Rows.account.tag
				$0.cell.height = {65}
			}
			.cellUpdate({ [weak self] (cell, row) in
				cell.avatarImageView.tintColor = UIColor.adamantChatIcons
				if let label = cell.addressLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				row.value = self?.accountService.account?.address
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, row) in
				guard let address = self?.accountService.account?.address else {
					return
				}
				
				let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
				
				self?.dialogService.presentShareAlertFor(string: encodedAddress,
														 types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
														 excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
														 animated: true,
														 completion: {
															guard let indexPath = row.indexPath else {
																return
															}
															self?.tableView.deselectRow(at: indexPath, animated: true)
														})
			})
		
		// MARK: Wallet section
		+++ Section(Sections.wallet.localized)
		// MARK: Balance
			<<< LabelRow() { [weak self] in
				$0.tag = Rows.balance.tag
				$0.title = Rows.balance.localized
				
				if let balance = self?.accountService?.account?.balance {
					$0.value = AdamantUtilities.format(balance: balance)
				}
			}
			.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			})
			.cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, _) in
				guard let vc = self?.router.get(scene: AdamantScene.Transactions.transactions), let nav = self?.navigationController else {
					return
				}
				
				nav.pushViewController(vc, animated: true)
			})
		
		// MARK: Send tokens
			<<< LabelRow() {
				$0.tag = Rows.sendTokens.tag
				$0.title = Rows.sendTokens.localized
			}
			.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			})
			.cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, row) in
				let alert = UIAlertController(title: String.adamantLocalized.account.sorryAlert, message: String.adamantLocalized.account.transferNotAllowed, preferredStyle: .alert)
				
				let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel) { _ in
					guard let indexPath = row.indexPath else {
						return
					}
					
					self?.tableView.deselectRow(at: indexPath, animated: true)
				}
				
				alert.addAction(cancel)
				
				if let url = self?.webAppUrl {
					let webApp = UIAlertAction(title: String.adamantLocalized.account.webApp, style: .default) { [weak self] _ in
						let safari  = SFSafariViewController(url: url)
						safari.preferredControlTintColor = UIColor.adamantPrimary
						self?.present(safari, animated: true, completion: nil)
					}
					alert.addAction(webApp)
				}
				
				self?.present(alert, animated: true, completion: nil)
			})
		
		// MARK: ICO
			<<< LabelRow() {
				$0.tag = Rows.invest.tag
				$0.title = Rows.invest.localized
			}
			.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			})
			.cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, _) in
				guard let address = self?.accountService.account?.address,
					let url = URL(string:  String.localizedStringWithFormat(String.adamantLocalized.account.joinIcoUrlFormat, address)) else {
					return
				}
				
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamantPrimary
				self?.present(safari, animated: true, completion: nil)
			})
		
		// MARK: Free Tokens
			<<< LabelRow() {
				$0.tag = Rows.freeTokens.tag
				$0.title = Rows.freeTokens.localized
				$0.hidden = Condition.function([], { [weak self] _ -> Bool in
					guard let hideFreeTokensRow = self?.hideFreeTokensRow else {
						return true
					}
					
					return hideFreeTokensRow
				})
			}
			.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			})
			.cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, _) in
				guard let address = self?.accountService.account?.address,
					let url = URL(string: String.localizedStringWithFormat(String.adamantLocalized.account.getFreeTokensUrlFormat, address)) else {
						return
				}
				
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamantPrimary
				self?.present(safari, animated: true, completion: nil)
			})
			
			
		// MARK: Actions section
		+++ Section(Sections.actions.localized)
			
			<<< LabelRow() {
				$0.tag = Rows.logout.tag
				$0.title = Rows.logout.localized
			}
			.cellSetup({ (cell, _) in
				cell.selectionStyle = .gray
			})
			.cellUpdate({ (cell, _) in
				if let label = cell.textLabel {
					label.font = UIFont.adamantPrimary(size: 17)
					label.textColor = UIColor.adamantPrimary
				}
				
				cell.accessoryType = .disclosureIndicator
			})
			.onCellSelection({ [weak self] (_, row) in
				guard let address = self?.accountService.account?.address else {
					return
				}
				
				let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamantLocalized.alert.logoutMessageFormat, address), message: nil, preferredStyle: .alert)
				let cancel = UIAlertAction(title: String.adamantLocalized.alert.cancel, style: .cancel) { _ in
					guard let indexPath = row.indexPath else {
						return
					}
					
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
				self?.present(alert, animated: true, completion: nil)
			})
		
		
		// MARK: Notifications
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.refreshBalanceCell()
		}
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.refreshBalanceCell()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.refreshBalanceCell()
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}


// MARK: - Other
extension WalletViewController {
	private func refreshBalanceCell() {
		let address: String?
		let balance: String?
		
		if let account = accountService.account {
			address = account.address
			balance = AdamantUtilities.format(balance: account.balance)
			hideFreeTokensRow = account.balance > 0
		} else {
			address = nil
			balance = nil
			hideFreeTokensRow = true
		}
		
		if let row: AccountRow = form.rowBy(tag: Rows.account.tag) {
			row.value = address
			row.reload()
		}
		
		if let row: LabelRow = form.rowBy(tag: Rows.balance.tag) {
			row.value = balance
			row.reload()
		}
		
		if let row: LabelRow = form.rowBy(tag: Rows.freeTokens.tag) {
			row.evaluateHidden()
		}
	}
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        accountService.update { [weak self] (result) in
            switch result {
            case .success:
				guard let tableView = self?.tableView else {
					break
				}
				
				DispatchQueue.main.async {
					tableView.reloadData()
				}
				
            case .failure(let error):
				self?.dialogService.showRichError(error: error)
            }
            
            DispatchQueue.main.async {
                refreshControl.endRefreshing()
            }
        }
    }
}
