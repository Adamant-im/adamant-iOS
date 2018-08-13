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
import Parchment


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
fileprivate extension WalletEnum {
	var sectionTag: String {
		switch self {
		case .adamant: return "s_adm"
		case .ethereum: return "s_eth"
        case .lisk: return "s_lsk"
		}
	}
	
	var sectionTitle: String {
		switch self {
		case .adamant: return NSLocalizedString("AccountTab.Sections.adamant_wallet", comment: "Account tab: Adamant wallet section")
		case .ethereum: return NSLocalizedString("AccountTab.Sections.ethereum_wallet", comment: "Account tab: Ethereum wallet section")
        case .lisk: return NSLocalizedString("AccountTab.Sections.lisk_wallet", comment: "Account tab: Lisk wallet section")
		}
	}
}


// MARK: AccountViewController
class AccountViewController: FormViewController {
	// MARK: - Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var router: Router!
    var ethApiService: EthApiService!
    var lskApiService: LskApiService!
	var notificationsService: NotificationsService!
	var transfersProvider: TransfersProvider!
	
	
	// MARK: - Properties
	
	var hideFreeTokensRow = false
	
	let walletCellIdentifier = "wllt"
	private (set) var accountHeaderView: AccountHeaderView!
	
	private var transfersController: NSFetchedResultsController<TransferTransaction>?
	private var pagingViewController: PagingViewController<WalletPagingItem>!
	
	
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationOptions = .Disabled
		navigationController?.setNavigationBarHidden(true, animated: false)
		
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
		
		if #available(iOS 11.0, *), let topInset = UIApplication.shared.keyWindow?.safeAreaInsets.top, topInset > 0 {
			accountHeaderView.backgroundTopConstraint.constant = -topInset
		}
		
		updateAccountInfo()
		
		tableView.tableHeaderView = header
		
		if let footer = UINib(nibName: "AccountFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableFooterView = footer
		}
		
		// MARK: Wallet view
		pagingViewController = PagingViewController<WalletPagingItem>()
		
		pagingViewController.menuItemSource = .nib(nib: UINib(nibName: "WalletCollectionViewCell", bundle: nil))
		pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
		pagingViewController.indicatorColor = UIColor.adamantPrimary
		pagingViewController.dataSource = self
		pagingViewController.select(index: 0)
		accountHeaderView.walletViewContainer.addSubview(pagingViewController.view)
		accountHeaderView.walletViewContainer.constrainToEdges(pagingViewController.view)
		addChildViewController(pagingViewController)
		
		// MARK: Application
		form +++ Section(Sections.application.localized) {
			$0.tag = Sections.application.tag
		}
			
		// Security
		<<< LabelRow() {
			$0.title = Rows.security.localized
			$0.tag = Rows.security.tag
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
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
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
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
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
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
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
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
			$0.cell.imageView?.image = #imageLiteral(resourceName: "row_icon_placeholder")
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
		
		
		form.allRows.forEach { $0.baseCell.imageView?.tintColor = UIColor.adamantSecondary; }
		
		
		// MARK: Notification Center
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.updateAccountInfo()
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
		let adamantWallet: WalletEnum
		
		if let account = accountService.account {
			address = account.address
			adamantWallet = WalletEnum.adamant(balance: account.balance)
			hideFreeTokensRow = account.balance > 0
		} else {
			address = ""
			adamantWallet = WalletEnum.adamant(balance: 0)
			hideFreeTokensRow = true
		}
		
		if let row: AlertLabelRow = form.rowBy(tag: Rows.balance.tag) {
			row.value = adamantWallet.formattedFull
			row.updateCell()
		}
		
		if let row: LabelRow = form.rowBy(tag: Rows.freeTokens.tag) {
			row.evaluateHidden()
		}
		
//		accountHeaderView.walletCollectionView.selectItem(at: IndexPath(row: selectedWalletIndex, section: 0), animated: false, scrollPosition: .centeredHorizontally)
		accountHeaderView.addressButton.setTitle(address, for: .normal)
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
		
		dialogService.presentShareAlertFor(string: address,
										   types: [.copyToPasteboard, .share, .generateQr(sharingTip: address)],
										   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
										   animated: true,
										   completion: completion)
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension AccountViewController: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//		accountHeaderView.walletCollectionView.reloadItems(at: [IndexPath(row: 0, section: 0)])
		
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


// MARK: - PagingViewControllerDataSource
extension AccountViewController: PagingViewControllerDataSource, PagingViewControllerDelegate {
	func numberOfViewControllers<T>(in pagingViewController: PagingViewController<T>) -> Int {
		return accountService.wallets.count
	}
	
	func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
		return accountService.wallets[index].walletViewController.viewController
	}
	
	func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
		let service = accountService.wallets[index]
		
		guard let wallet = service.wallet else {
			return WalletPagingItem(index: index, currencySymbol: "", currencyImage: #imageLiteral(resourceName: "wallet_adm")) as! T
		}
		
		let serviceType = type(of: service)
		
		let item = WalletPagingItem(index: index, currencySymbol: serviceType.currencySymbol, currencyImage: serviceType.currencyLogo)
		item.balance = wallet.balance
		
		return item as! T
	}
	
//	func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
//		guard transitionSuccessful,
//			let walletVC = destinationViewController as? WalletViewController else {
//			return
//		}
//
//		guard case let .fixed(_, height) = pagingViewController.menuItemSize else {
//			return
//		}
//	}
}


// MARK: - Rows & Sections
fileprivate extension AccountViewController {
	enum Sections {
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
	
	enum Rows {
		case balance, balanceEth, balanceLsk, sendTokens, buyTokens, freeTokens // Wallet
		case security, nodes, about // Application
		case voteForDelegates // Delegates
		case logout // Actions
		
		var tag: String {
			switch self {
			case .balance: return "blnc"
			case .balanceEth: return "blncEth"
			case .balanceLsk: return "blncLsk"
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
			case .balance, .balanceEth, .balanceLsk: return NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
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
	}
}
