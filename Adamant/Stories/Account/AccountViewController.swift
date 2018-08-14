//
//  AccountViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices
import FreakingSimpleRoundImageView
import CoreData


// MARK: - Localization
extension String.adamantLocalized {
	struct account {
		static let title = NSLocalizedString("AccountTab.Title", comment: "Account page: scene title")
		
		// URLs
		static let getFreeTokensUrlFormat = NSLocalizedString("AccountTab.FreeTokens.UrlFormat", comment: "Account tab: A full 'Get free tokens' link, with %@ as address")
		static let buyTokensUrlFormat = NSLocalizedString("AccountTab.BuyTokens.UrlFormat", comment: "Account tab: A full 'Buy tokens' link, with %@ as address")
		
		private init() { }
	}
}

extension String.adamantLocalized.alert {
	static let logoutMessageFormat = NSLocalizedString("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
	static let logoutButton = NSLocalizedString("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
}


// MARK: - Wallet extension
fileprivate extension Wallet {
	var sectionTag: String {
		switch self {
		case .adamant: return "s_adm"
		case .ethereum: return "s_eth"
		}
	}
	
	var sectionTitle: String {
		switch self {
		case .adamant: return NSLocalizedString("AccountTab.Sections.adamant_wallet", comment: "Account tab: Adamant wallet section")
		case .ethereum: return NSLocalizedString("AccountTab.Sections.ethereum_wallet", comment: "Account tab: Ethereum wallet section")
		}
	}
}


// MARK: AccountViewController
class AccountViewController: FormViewController {
	// MARK: - Rows & Sections
	private enum Sections {
		case wallet, application, delegates, actions
		
		var tag: String {
			switch self {
			case .wallet: return "wllt"
			case .application: return "app"
			case .actions: return "actns"
            case .delegates: return "dlgts"
			}
		}
		
		var localized: String {
			switch self {
			case .wallet: return "Wallet"	// Depends on selected wallet
			case .application: return NSLocalizedString("AccountTab.Section.Application", comment: "Account tab: Application section title")
			case .actions: return NSLocalizedString("AccountTab.Section.Actions", comment: "Account tab: Actions section title")
            case .delegates: return NSLocalizedString("AccountTab.Section.Delegates", comment: "Account tab: Delegates section title")
			}
		}
	}
	
	private enum Rows {
		case balance, sendTokens, buyTokens, freeTokens // Wallet
		case security, nodes, about // Application
		case voteForDelegates // Delegates
		case logout // Actions
		
		var tag: String {
			switch self {
			case .balance: return "blnc"
			case .sendTokens: return "sndTkns"
			case .buyTokens: return "bTkns"
			case .freeTokens: return "frrTkns"
			case .security: return "scrt"
			case .nodes: return "nds"
			case .about: return "bt"
			case .logout: return "lgtrw"
            case .voteForDelegates:
                return "vtFrDlgts"
			}
		}
		
		var localized: String {
			switch self {
			case .balance: return NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
			case .sendTokens: return NSLocalizedString("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
			case .buyTokens: return NSLocalizedString("AccountTab.Row.BuyTokens", comment: "Account tab: 'Buy tokens' button")
			case .freeTokens: return NSLocalizedString("AccountTab.Row.FreeTokens", comment: "Account tab: 'Get free tokens' button")
			case .security: return NSLocalizedString("AccountTab.Row.Security", comment: "Account tab: 'Security' row")
			case .nodes: return String.adamantLocalized.nodesList.nodesListButton
			case .about: return NSLocalizedString("AccountTab.Row.About", comment: "Account tab: 'About' row")
			case .logout: return NSLocalizedString("AccountTab.Row.Logout", comment: "Account tab: 'Logout' button")
			case .voteForDelegates: return NSLocalizedString("AccountTab.Row.VoteForDelegates", comment: "Account tab: 'Votes for delegates' button")
			}
		}
		
		var image: UIImage? {
			switch self {
			case .security: return #imageLiteral(resourceName: "row_security")
			case .about: return #imageLiteral(resourceName: "row_about")
			case .nodes: return #imageLiteral(resourceName: "row_nodes")
			case .balance: return #imageLiteral(resourceName: "row_balance")
			case .buyTokens: return #imageLiteral(resourceName: "row_buy-coins")
			case .voteForDelegates: return #imageLiteral(resourceName: "row_vote-delegates")
			case .logout: return #imageLiteral(resourceName: "row_logout")
			case .freeTokens: return #imageLiteral(resourceName: "row_free-tokens")
			case .sendTokens: return #imageLiteral(resourceName: "row_icon_placeholder") // TODO:
			}
		}
	}
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var router: Router!
	var notificationsService: NotificationsService!
	var transfersProvider: TransfersProvider!
	
	
	// MARK: - Wallets
	var selectedWalletIndex: Int = 0
	
	
	// MARK: - Properties
	
	var hideFreeTokensRow = false
	
	let walletCellIdentifier = "wllt"
	private (set) var accountHeaderView: AccountHeaderView!
	var wallets: [Wallet]? {
		didSet {
			selectedWalletIndex = 0
			accountHeaderView?.walletCollectionView.reloadData()
		}
	}
	
	private var transfersController: NSFetchedResultsController<TransferTransaction>?
	
	private let accessoryContentInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
	private let accessoryContainerInsets = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationOptions = .Disabled
		navigationController?.setNavigationBarHidden(true, animated: false)
		
		wallets = [.adamant(balance: Decimal(floatLiteral: 100.001)), .ethereum]
		
		// MARK: Transfers controller
		let controller = transfersProvider.unreadTransfersController()
		controller.delegate = self
		transfersController = controller
		
		do {
			try controller.performFetch()
		} catch {
			dialogService.showError(withMessage: "Error fetching transfers: report a bug", error: error)
		}

		
		// MARK: Header&Footer
		guard let header = UINib(nibName: "AccountHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? AccountHeaderView else {
			fatalError("Can't load AccountHeaderView")
		}
		
		accountHeaderView = header
		accountHeaderView.delegate = self
		accountHeaderView.walletCollectionView.delegate = self
		accountHeaderView.walletCollectionView.dataSource = self
		accountHeaderView.walletCollectionView.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: walletCellIdentifier)
		
		if #available(iOS 11.0, *), let topInset = UIApplication.shared.keyWindow?.safeAreaInsets.top, topInset > 0 {
			accountHeaderView.backgroundTopConstraint.constant = -topInset
		}
		
		updateAccountInfo()
		
		tableView.tableHeaderView = header
		
		if let footer = UINib(nibName: "AccountFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableFooterView = footer
		}
		
		
		// MARK: Wallets
		if let wallets = wallets {
			for (walletIndex, wallet) in wallets.enumerated() {
				let section = createSectionFor(wallet: wallet)
				
				section.hidden = Condition.function([], { [weak self] _ -> Bool in
					guard let selectedIndex = self?.selectedWalletIndex else {
						return true
					}
					
					return walletIndex != selectedIndex
				})
				
				form.append(section)
			}
		}
		
		
		// MARK: Application
		form +++ Section(Sections.application.localized) {
			$0.tag = Sections.application.tag
		}
			
		// Security
		<<< LabelRow() {
			$0.title = Rows.security.localized
			$0.tag = Rows.security.tag
			$0.cell.imageView?.image = Rows.security.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, _) in
			guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.Settings.security) else {
				return
			}
			
			nav.pushViewController(vc, animated: true)
		})
		
		// Node list
		<<< LabelRow() {
			$0.title = Rows.nodes.localized
			$0.tag = Rows.nodes.tag
			$0.cell.imageView?.image = Rows.nodes.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, _) in
			guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.NodesEditor.nodesList) else {
				return
			}
			
			nav.pushViewController(vc, animated: true)
		})
		
		// About
		<<< LabelRow() {
			$0.title = Rows.about.localized
			$0.tag = Rows.about.tag
			$0.cell.imageView?.image = Rows.about.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, _) in
			guard let nav = self?.navigationController, let vc = self?.router.get(scene: AdamantScene.Settings.about) else {
				return
			}
			
			nav.pushViewController(vc, animated: true)
		})
		
			
		// MARK: Actions
		+++ Section(Sections.actions.localized) {
			$0.tag = Sections.actions.tag
		}
		
		// Delegates
		<<< LabelRow() {
			$0.tag = Rows.voteForDelegates.tag
			$0.title = Rows.voteForDelegates.localized
			$0.cell.imageView?.image = Rows.voteForDelegates.image
		}.cellSetup({ (cell, _) in
			cell.selectionStyle = .gray
		}).cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, row) in
			guard let vc = self?.router.get(scene: AdamantScene.Delegates.delegates), let nav = self?.navigationController else {
				return
			}
			
			nav.pushViewController(vc, animated: true)
		})
		
		// Logout
		<<< LabelRow() {
			$0.title = Rows.logout.localized
			$0.tag = Rows.logout.tag
			$0.cell.imageView?.image = Rows.logout.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate({ (cell, _) in
			cell.accessoryType = .disclosureIndicator
		}).onCellSelection({ [weak self] (_, row) in
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
		
		
		form.allRows.forEach { $0.baseCell.imageView?.tintColor = UIColor.adamant.tableRowIcons }
		
		accountHeaderView.walletCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
		
		
		// MARK: Notification Center
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.updateAccountInfo()
			self?.tableView.setContentOffset(CGPoint.zero, animated: false)
		}
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.updateAccountInfo()
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.updateAccountInfo()
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if #available(iOS 11.0, *) {
			navigationController?.navigationBar.prefersLargeTitles = false
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	
	// MARK: TableView configuration
	
	override func insertAnimation(forSections sections: [Section]) -> UITableViewRowAnimation {
		return .fade
	}
	
	override func deleteAnimation(forSections sections: [Section]) -> UITableViewRowAnimation {
		return .fade
	}
	
	
	// MARK: Other
	func updateAccountInfo() {
		let address: String
		let adamantWallet: Wallet
		
		if let account = accountService.account {
			address = account.address
			adamantWallet = Wallet.adamant(balance: account.balance)
			hideFreeTokensRow = account.balance > 0
		} else {
			address = ""
			adamantWallet = Wallet.adamant(balance: 0)
			hideFreeTokensRow = true
		}
		
		if wallets != nil {
			wallets![0] = adamantWallet
			accountHeaderView.walletCollectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
		} else {
			wallets = [adamantWallet, Wallet.ethereum]
			accountHeaderView.walletCollectionView.reloadData()
		}
		
		if let row: AlertLabelRow = form.rowBy(tag: Rows.balance.tag) {
			row.value = adamantWallet.format(numberFormat: .full, includeCurrencySymbol: true)
			row.updateCell()
		}
		
		if let row: LabelRow = form.rowBy(tag: Rows.freeTokens.tag) {
			row.evaluateHidden()
		}
		
		accountHeaderView.walletCollectionView.selectItem(at: IndexPath(row: selectedWalletIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
		accountHeaderView.addressButton.setTitle(address, for: .normal)
	}
}


// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension AccountViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let wallets = wallets else {
			return 0
		}
		
		return wallets.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: walletCellIdentifier, for: indexPath) as? WalletCollectionViewCell else {
			fatalError("Can't dequeue wallet cell")
		}
		
		guard let wallet = wallets?[indexPath.row] else {
			fatalError("Wallets collectionView: Out of bounds row")
		}
		
		if !cell.isInitialized {
			cell.tintColor = UIColor.adamant.secondary
			
			cell.balanceLabel.textColor = UIColor.adamant.primary
			cell.currencySymbolLabel.textColor = UIColor.adamant.primary
			
			cell.accessoryContainerView.accessoriesBackgroundColor = UIColor.adamant.primary
			cell.accessoryContainerView.accessoriesBorderColor = UIColor.white
			cell.accessoryContainerView.accessoriesBorderWidth = 2
			
			if cell.accessoryContainerView.accessoriesContentInsets != accessoryContentInsets {
				cell.accessoryContainerView.accessoriesContentInsets = accessoryContentInsets
			}
			
			if cell.accessoryContainerView.accessoriesContainerInsets == accessoryContainerInsets {
				cell.accessoryContainerView.accessoriesContainerInsets = accessoryContainerInsets
			}
			
			cell.isInitialized = true
		}
		
		cell.currencyImageView.image = wallet.currencyLogo
		cell.balanceLabel.text = wallet.format(numberFormat: .compact, includeCurrencySymbol: false)
		cell.currencySymbolLabel.text = wallet.currencySymbol
		
		if indexPath.row == 0, let count = transfersController?.fetchedObjects?.count, count > 0 {
			let accessory = AccessoryType.label(text: String(count))
			cell.accessoryContainerView.setAccessory(accessory, at: AccessoryPosition.topRight)
		} else {
			cell.accessoryContainerView.setAccessory(nil, at: AccessoryPosition.topRight)
		}
		
		cell.setSelected(indexPath.row == selectedWalletIndex, animated: false)
		
		if wallet.enabled {
			cell.currencyImageView.alpha = 1
			cell.currencySymbolLabel.alpha = 1
		} else {
			cell.currencyImageView.alpha = 0.3
			cell.currencySymbolLabel.alpha = 0.3
		}
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
		guard let wallet = wallets?[indexPath.row] else {
			return false
		}
		
		return wallet.enabled
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selectedWalletIndex = indexPath.row

		form.allSections.filter { $0.hidden != nil }.forEach { $0.evaluateHidden() }

		if let cell = collectionView.cellForItem(at: indexPath) as? WalletCollectionViewCell {
			cell.setSelected(true, animated: true)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? WalletCollectionViewCell {
			cell.setSelected(false, animated: true)
		}
	}
	
	// Flow delegate
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 110, height: 110)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.zero
	}
}



// MARK: - AccountHeaderViewDelegate
extension AccountViewController: AccountHeaderViewDelegate {
	func addressLabelTapped() {
		guard let address = accountService.account?.address else {
			return
		}
		
		let completion = { [weak self] in
			guard let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow else {
				return
			}
			
			tableView.deselectRow(at: indexPath, animated: true)
		}
		
		let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
		dialogService.presentShareAlertFor(string: encodedAddress,
										   types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
										   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
										   animated: true,
										   completion: completion)
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension AccountViewController: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		accountHeaderView.walletCollectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
		
		if let row: AlertLabelRow = form.rowBy(tag: Rows.balance.tag), let alertLabel = row.cell.alertLabel, let count = controller.fetchedObjects?.count {
			if count > 0 {
				alertLabel.isHidden = false
				alertLabel.text = String(count)
			} else {
				alertLabel.isHidden = true
			}
		}
	}
}


// MARK: - Tools
extension AccountViewController {
	func createSectionFor(wallet: Wallet) -> Section {
		let section = Section(wallet.sectionTitle) {
			$0.tag = wallet.sectionTag
		}
		
		switch wallet {
		case .adamant:
			// Balance
			section <<< AlertLabelRow() { [weak self] in
				$0.title = Rows.balance.localized
				$0.tag = Rows.balance.tag
				$0.value = wallet.format(numberFormat: .full, includeCurrencySymbol: true)
				$0.cell.imageView?.image = Rows.balance.image
				$0.cell.selectionStyle = .gray
				
				if let alertLabel = $0.cell.alertLabel {
					alertLabel.backgroundColor = UIColor.adamant.primary
					alertLabel.textColor = UIColor.white
					alertLabel.clipsToBounds = true
					alertLabel.textInsets = UIEdgeInsets(top: 1, left: 5, bottom: 1, right: 5)
					
					if let count = self?.transfersController?.fetchedObjects?.count, count > 0 {
						alertLabel.text = String(count)
					} else {
						alertLabel.isHidden = true
					}
				}
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}).onCellSelection({ [weak self] (_, _) in
				guard let vc = self?.router.get(scene: AdamantScene.Transactions.transactions), let nav = self?.navigationController else {
					return
				}
				
				nav.pushViewController(vc, animated: true)
			})
			
			// Send Tokens
//			<<< LabelRow() {
//				$0.title = Rows.sendTokens.localized
//				$0.tag = Rows.sendTokens.tag
//				$0.cell.imageView?.image = Rows.sendTokens.image
//				$0.cell.selectionStyle = .gray
//			}.cellUpdate({ (cell, _) in
//				cell.accessoryType = .disclosureIndicator
//			})
			
			// Buy tokens
			<<< LabelRow() {
				$0.title = Rows.buyTokens.localized
				$0.tag = Rows.buyTokens.tag
				$0.cell.imageView?.image = Rows.buyTokens.image
				$0.cell.selectionStyle = .gray
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}).onCellSelection({ [weak self] (_, _) in
				let urlOpt: URL?
				if let address = self?.accountService.account?.address {
					urlOpt = URL(string: String.localizedStringWithFormat(String.adamantLocalized.account.buyTokensUrlFormat, address))
				} else {
					urlOpt = nil
				}
				
				guard let url = urlOpt else {
					self?.dialogService.showError(withMessage: "Failed to build 'Buy tokens' url, report a bug", error: nil)
					return
				}
				
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamant.primary
				self?.present(safari, animated: true, completion: nil)
			})
			
			// Get free tokens
			<<< LabelRow() {
				$0.title = Rows.freeTokens.localized
				$0.tag = Rows.freeTokens.tag
				$0.cell.imageView?.image = Rows.freeTokens.image
				$0.cell.selectionStyle = .gray
				
				$0.hidden = Condition.function([], { [weak self] _ -> Bool in
					guard let hideFreeTokensRow = self?.hideFreeTokensRow else {
						return true
					}
					
					return hideFreeTokensRow
				})
			}.cellUpdate({ (cell, _) in
				cell.accessoryType = .disclosureIndicator
			}).onCellSelection({ [weak self] (_, _) in
				let raw: URL?
				if let address = self?.accountService.account?.address {
					raw = URL(string: String.localizedStringWithFormat(String.adamantLocalized.account.getFreeTokensUrlFormat, address))
				} else {
					raw = URL(string: String.adamantLocalized.account.getFreeTokensUrlFormat)
				}
				
				guard let url = raw else {
					self?.dialogService.showError(withMessage: "Failed to build 'Free tokens' url, report a bug", error: nil)
					return
				}
				
				let safari = SFSafariViewController(url: url)
				safari.preferredControlTintColor = UIColor.adamant.primary
				self?.present(safari, animated: true, completion: nil)
			})
			
		case .ethereum:
			section <<< LabelRow() {
				$0.title = "Soon..."
			}
		}
		
		return section
	}
}
