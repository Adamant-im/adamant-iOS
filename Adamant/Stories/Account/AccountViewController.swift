//
//  AccountViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import FreakingSimpleRoundImageView
import CoreData
import Parchment


// MARK: - Localization
extension String.adamantLocalized {
	struct account {
		static let title = NSLocalizedString("AccountTab.Title", comment: "Account page: scene title")
		
        static let updatingBalance = "…"
        
		private init() { }
	}
}

extension String.adamantLocalized.alert {
	static let logoutMessageFormat = NSLocalizedString("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
	static let logoutButton = NSLocalizedString("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
}

// MARK: AccountViewController
class AccountViewController: FormViewController {
	// MARK: - Rows & Sections
	enum Sections {
		case wallet, application, delegates, actions, security
		
		var tag: String {
			switch self {
			case .wallet: return "wllt"
			case .application: return "app"
			case .actions: return "actns"
            case .delegates: return "dlgts"
            case .security: return "scrty"
			}
		}
		
		var localized: String {
			switch self {
			case .wallet: return "Wallet"	// Depends on selected wallet
			case .application: return NSLocalizedString("AccountTab.Section.Application", comment: "Account tab: Application section title")
			case .actions: return NSLocalizedString("AccountTab.Section.Actions", comment: "Account tab: Actions section title")
            case .delegates: return NSLocalizedString("AccountTab.Section.Delegates", comment: "Account tab: Delegates section title")
            case .security: return Rows.security.localized
			}
		}
	}
	
	enum Rows {
		case balance, sendTokens // Wallet
		case security, nodes, theme, currency, about // Application
		case voteForDelegates, generateQr, logout // Actions
        case stayIn, biometry, notifications // Security
		
		var tag: String {
			switch self {
			case .balance: return "blnc"
			case .sendTokens: return "sndTkns"
			case .security: return "scrt"
            case .theme: return "thm"
            case .currency: return "crrnc"
			case .nodes: return "nds"
			case .about: return "bt"
			case .logout: return "lgtrw"
            case .voteForDelegates: return "vtFrDlgts"
            case .generateQr: return "qr"
            case .stayIn: return "stayin"
            case .biometry: return "biometry"
            case .notifications: return "notifications"
			}
		}
		
		var localized: String {
			switch self {
			case .balance: return NSLocalizedString("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
			case .sendTokens: return NSLocalizedString("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
			case .security: return NSLocalizedString("AccountTab.Row.Security", comment: "Account tab: 'Security' row")
            case .theme: return NSLocalizedString("AccountTab.Row.Theme", comment: "Account tab: 'Theme' row")
            case .currency: return NSLocalizedString("AccountTab.Row.Currency", comment: "Account tab: 'Currency' row")
			case .nodes: return String.adamantLocalized.nodesList.nodesListButton
			case .about: return NSLocalizedString("AccountTab.Row.About", comment: "Account tab: 'About' row")
			case .logout: return NSLocalizedString("AccountTab.Row.Logout", comment: "Account tab: 'Logout' button")
			case .voteForDelegates: return NSLocalizedString("AccountTab.Row.VoteForDelegates", comment: "Account tab: 'Votes for delegates' button")
            case .generateQr: return NSLocalizedString("SecurityPage.Row.GenerateQr", comment: "Security: Generate QR with passphrase row")
            case .stayIn: return SecurityViewController.Rows.stayIn.localized
            case .biometry: return SecurityViewController.Rows.biometry.localized
            case .notifications: return SecurityViewController.Rows.notificationsMode.localized
			}
		}
		
		var image: UIImage? {
			switch self {
			case .security: return #imageLiteral(resourceName: "row_security")
			case .about: return #imageLiteral(resourceName: "row_about")
			case .theme: return #imageLiteral(resourceName: "row_themes.png")
            case .currency: return #imageLiteral(resourceName: "row_currency")
            case .nodes: return #imageLiteral(resourceName: "row_nodes")
			case .balance: return #imageLiteral(resourceName: "row_balance")
            case .voteForDelegates: return #imageLiteral(resourceName: "row_vote-delegates")
            case .logout: return #imageLiteral(resourceName: "row_logout")
			case .sendTokens: return nil
            case .generateQr: return #imageLiteral(resourceName: "row_QR.png")
            case .stayIn: return #imageLiteral(resourceName: "row_security")
            case .biometry: return nil // Determined by localAuth service
            case .notifications: return #imageLiteral(resourceName: "row_Notifications.png")
			}
		}
	}
	
	// MARK: - Dependencies
	var accountService: AccountService!
	var dialogService: DialogService!
	var router: Router!
	var notificationsService: NotificationsService!
	var transfersProvider: TransfersProvider!
    var localAuth: LocalAuthentication!
	
    var avatarService: AvatarService!
    
    var currencyInfoService: CurrencyInfoService!
	
	// MARK: - Properties
	
	let walletCellIdentifier = "wllt"
	private (set) var accountHeaderView: AccountHeaderView!
	
	private var transfersController: NSFetchedResultsController<TransferTransaction>?
	private var pagingViewController: PagingViewController<WalletPagingItem>!
	
	private var initiated = false
	
    private var walletViewControllers = [WalletViewControllerBase]()
    
    // MARK: StayIn
    
    var showLoggedInOptions: Bool {
        return accountService.hasStayInAccount
    }
    
    var showBiometryOptions: Bool {
        switch localAuth.biometryType {
        case .none:
            return false
            
        case .touchID, .faceID:
            return showLoggedInOptions
        }
    }
    
    var pinpadRequest: SecurityViewController.PinpadRequest?
    
    
	// MARK: - Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		navigationOptions = .Disabled
		navigationController?.setNavigationBarHidden(true, animated: false)
        
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .never
        }
		
		// MARK: Status Bar
		let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
		statusBarView.backgroundColor = UIColor.white
		view.addSubview(statusBarView)
        
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
		
		updateAccountInfo()
		
		tableView.tableHeaderView = header
		
		if let footer = UINib(nibName: "AccountFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
			tableView.tableFooterView = footer
		}
		
		// MARK: Wallet view
		pagingViewController = PagingViewController<WalletPagingItem>()
		
		pagingViewController.menuItemSource = .nib(nib: UINib(nibName: "WalletCollectionViewCell", bundle: nil))
		pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
		pagingViewController.indicatorColor = UIColor.adamant.primary
		pagingViewController.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
		pagingViewController.dataSource = self
		pagingViewController.delegate = self
		pagingViewController.select(index: 0)
		accountHeaderView.walletViewContainer.addSubview(pagingViewController.view)
		accountHeaderView.walletViewContainer.constrainToEdges(pagingViewController.view)
        addChild(pagingViewController)
        
        pagingViewController.borderColor = UIColor.clear
		
		for wallet in accountService.wallets {
			NotificationCenter.default.addObserver(forName: wallet.walletUpdatedNotification, object: nil, queue: OperationQueue.main) { [weak self] _ in
				self?.pagingViewController.reloadData()
			}
		}
		
        // MARK: Rows&Sections
        
		// MARK: Application
        let appSection = Section(Sections.application.localized) {
			$0.tag = Sections.application.tag
		}

		// Node list
		let nodesRow = LabelRow() {
			$0.title = Rows.nodes.localized
			$0.tag = Rows.nodes.tag
			$0.cell.imageView?.image = Rows.nodes.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
			guard let vc = self?.router.get(scene: AdamantScene.NodesEditor.nodesList) else {
				return
			}
			
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
        }

        appSection.append(nodesRow)

        // Currency select
        let currencyRow = PushRow<Currency>() {
            $0.title = Rows.currency.localized
            $0.tag = Rows.currency.tag
            $0.cell.imageView?.image = Rows.currency.image
            $0.options = [Currency.USD, Currency.EUR, Currency.RUB, Currency.CNY, Currency.JPY]
            $0.value = currencyInfoService.currentCurrency
            $0.selectorTitle = Rows.currency.localized
        }.onPresent { from, to in
            to.selectableRowCellUpdate = { cell, row in
                cell.textLabel?.text = "\(row.selectableValue!.rawValue) (\(row.selectableValue!.symbol))"
            }
        }.onChange { row in
            if let value = row.value {
                self.currencyInfoService.currentCurrency = value
            }
        }
        
        appSection.append(currencyRow)

		// About
		let aboutRow = LabelRow() {
			$0.title = Rows.about.localized
			$0.tag = Rows.about.tag
			$0.cell.imageView?.image = Rows.about.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
			guard let vc = self?.router.get(scene: AdamantScene.Settings.about) else {
				return
			}
			
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
		}
		
        appSection.append(aboutRow)
			
		// MARK: Actions
		let actionsSection = Section(Sections.actions.localized) {
			$0.tag = Sections.actions.tag
		}
		
		// Delegates
		let delegatesRow = LabelRow() {
			$0.tag = Rows.voteForDelegates.tag
			$0.title = Rows.voteForDelegates.localized
			$0.cell.imageView?.image = Rows.voteForDelegates.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
			guard let vc = self?.router.get(scene: AdamantScene.Delegates.delegates) else {
				return
			}
			
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                details.definesPresentationContext = true
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
		}
        
        actionsSection.append(delegatesRow)
            
        // Generate passphrase QR
        let generateQrRow = LabelRow() {
            $0.title = Rows.generateQr.localized
            $0.tag = Rows.generateQr.tag
            $0.cell.imageView?.image = Rows.generateQr.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.router.get(scene: AdamantScene.Settings.qRGenerator) else {
                return
            }
            
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
        }

        actionsSection.append(generateQrRow)

		// Logout
		let logoutRow = LabelRow() {
			$0.title = Rows.logout.localized
			$0.tag = Rows.logout.tag
			$0.cell.imageView?.image = Rows.logout.image
			$0.cell.selectionStyle = .gray
		}.cellUpdate { (cell, _) in
			cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
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
		}
        
        actionsSection.append(logoutRow)
		
        // MARK: Security section
        
        let securitySection = Section(Sections.security.localized) {
            $0.tag = Sections.security.tag
        }
        
        // Stay in
        
        let stayInRow = SwitchRow() {
            $0.tag = Rows.stayIn.tag
            $0.title = Rows.stayIn.localized
            $0.cell.imageView?.image = Rows.stayIn.image
            $0.value = accountService.hasStayInAccount
        }.cellUpdate { (cell, _) in
            cell.switchControl.onTintColor = UIColor.adamant.switchColor
        }.onChange { [weak self] row in
            guard let enabled = row.value else {
                return
            }
            
            self?.setStayLoggedIn(enabled: enabled)
        }
        
        securitySection.append(stayInRow)
        
        // Biometry
        let biometryRow = SwitchRow() { [weak self] in
            $0.tag = Rows.biometry.tag
            $0.title = localAuth.biometryType.localized
            $0.value = accountService.useBiometry
            
            if let auth = self?.localAuth {
                switch auth.biometryType {
                case .none: $0.cell.imageView?.image = nil
                case .touchID: $0.cell.imageView?.image = #imageLiteral(resourceName: "row_touchid.png")
                case .faceID: $0.cell.imageView?.image = #imageLiteral(resourceName: "row_faceid.png")
                }
            }
            
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showBiometry = self?.showBiometryOptions else {
                    return true
                }
                
                return !showBiometry
            })
        }.cellUpdate { (cell, _) in
            cell.switchControl.onTintColor = UIColor.adamant.switchColor
        }.onChange { [weak self] row in
            let value = row.value ?? false
            self?.setBiometry(enabled: value)
        }
        
        securitySection.append(biometryRow)
        
        // Notifications
        let notificationsRow = LabelRow() { [weak self] in
            $0.tag = Rows.notifications.tag
            $0.title = Rows.notifications.localized
            $0.cell.selectionStyle = .gray
            $0.value = self?.notificationsService.notificationsMode.localized
            $0.cell.imageView?.image = Rows.notifications.image
            
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showNotifications = self?.showLoggedInOptions else {
                    return true
                }
                
                return !showNotifications
            })
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.router.get(scene: AdamantScene.Settings.notifications) else {
                return
            }
            
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
        }
        
        securitySection.append(notificationsRow)
        
        // MARK: Appending sections
        form.append(securitySection)
        form.append(actionsSection)
        form.append(appSection)
        
		form.allRows.forEach { $0.baseCell.imageView?.tintColor = UIColor.adamant.tableRowIcons }
		
		
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.stayInChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let form = self?.form, let accountService = self?.accountService else {
                return
            }
            
            if let row: SwitchRow = form.rowBy(tag: Rows.stayIn.tag) {
                row.value = accountService.hasStayInAccount
                row.updateCell()
            }
            
            if let row: SwitchRow = form.rowBy(tag: Rows.biometry.tag) {
                row.value = accountService.hasStayInAccount && accountService.useBiometry
                row.evaluateHidden()
                row.updateCell()
            }
            
            if let row = form.rowBy(tag: Rows.notifications.tag) {
                row.evaluateHidden()
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantNotificationService.notificationsModeChanged, object: nil, queue: OperationQueue.main) { [weak self] notification in
            guard let newMode = notification.userInfo?[AdamantUserInfoKey.NotificationsService.newNotificationsMode] as? NotificationsMode else {
                return
            }
            
            guard let row: LabelRow = self?.form.rowBy(tag: Rows.notifications.tag) else {
                return
            }
            
            row.value = newMode.localized
            row.updateCell()
        }
		
		NotificationCenter.default.addObserver(forName: Notification.Name.WalletViewController.heightUpdated, object: nil, queue: OperationQueue.main) { [weak self] notification in
			if let vc = notification.object as? WalletViewController,
				let cvc = self?.pagingViewController.pageViewController.selectedViewController,
				vc.viewController == cvc {
				
				if let initiated = self?.initiated {
					self?.updateHeaderSize(with: vc, animated: initiated)
				} else {
					self?.updateHeaderSize(with: vc, animated: false)
				}
			}
		}
        
		for (index, service) in accountService.wallets.enumerated() {
			NotificationCenter.default.addObserver(forName: service.walletUpdatedNotification,
												   object: service,
												   queue: OperationQueue.main) { [weak self] _ in
													self?.pagingViewController.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
			}
		}
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            layoutTableHeaderView()
        }
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		navigationController?.setNavigationBarHidden(true, animated: animated)
		
		if let indexPath = tableView.indexPathForSelectedRow {
			tableView.deselectRow(at: indexPath, animated: animated)
		}
		
        for vc in pagingViewController.pageViewController.children {
			vc.viewWillAppear(animated)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.setNavigationBarHidden(false, animated: animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !initiated {
			initiated = true
		}
	}
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        }
        
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad, !initiated {
            layoutTableHeaderView()
            layoutTableFooterView()
        }
        
        pagingViewController?.indicatorColor = UIColor.adamant.primary
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	
	// MARK: TableView configuration
	
	override func insertAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
		return .fade
	}
	
	override func deleteAnimation(forSections sections: [Section]) -> UITableView.RowAnimation {
		return .fade
	}
	
	
	// MARK: Other
	func updateAccountInfo() {
		let address: String
		
		if let account = accountService.account {
			address = account.address
		} else {
			address = ""
		}
		
		accountHeaderView.addressButton.setTitle(address, for: .normal)
        
        if let publickey = accountService.keypair?.publicKey {
            DispatchQueue.global().async {
                let image = self.avatarService.avatar(for: publickey, size: 200)
                DispatchQueue.main.async {
                    self.accountHeaderView.avatarImageView.image = image
                }
            }
        }
	}
    
    func layoutTableHeaderView() {
        guard let view = tableView.tableHeaderView else { return }
        var frame = view.frame

        frame.size.height = 300
        view.frame = frame

        self.tableView.tableHeaderView = view
    }
    
    func layoutTableFooterView() {
        guard let view = tableView.tableFooterView else { return }
        view.translatesAutoresizingMaskIntoConstraints = false

        let width = view.bounds.size.width;
        let temporaryWidthConstraints = NSLayoutConstraint.constraints(withVisualFormat: "[footerView(width)]", options: NSLayoutConstraint.FormatOptions(rawValue: UInt(0)), metrics: ["width": width], views: ["footerView": view])

        view.addConstraints(temporaryWidthConstraints)

        view.setNeedsLayout()
        view.layoutIfNeeded()

        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let height = size.height
        var frame = view.frame

        frame.size.height = height
        view.frame = frame

        self.tableView.tableFooterView = view

        view.removeConstraints(temporaryWidthConstraints)
        view.translatesAutoresizingMaskIntoConstraints = true
    }
    
    private func deselectWalletViewControllers() {
        for vc in walletViewControllers {
            if let indexPath = vc.tableView.indexPathForSelectedRow {
                vc.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}


// MARK: - AccountHeaderViewDelegate
extension AccountViewController: AccountHeaderViewDelegate {
    func addressLabelTapped(from: UIView) {
		guard let address = accountService.account?.address else {
			return
		}
		
		let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
		dialogService.presentShareAlertFor(string: address,
                                           types: [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)],
										   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                           animated: true, from: from,
										   completion: nil)
	}
}


// MARK: - NSFetchedResultsControllerDelegate
extension AccountViewController: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
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
        let vc = accountService.wallets[index].walletViewController.viewController
        
        if let wallet = vc as? WalletViewControllerBase {
            wallet.delegate = self
            walletViewControllers.append(wallet)
        }
        
        return vc
	}
	
	func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
		let service = accountService.wallets[index]
        let serviceType = type(of: service)
        
        let item = WalletPagingItem(index: index, currencySymbol: serviceType.currencySymbol, currencyImage: serviceType.currencyLogo)
        
        if let wallet = service.wallet {
            item.balance = wallet.balance
            item.notifications = wallet.notifications
        } else {
            item.balance = nil
        }
        
        return item as! T
	}
	
	func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
		guard transitionSuccessful,
			let first = startingViewController as? WalletViewController,
			let second = destinationViewController as? WalletViewController,
			first.height != second.height else {
			return
		}

		updateHeaderSize(with: second, animated: true)
	}
	
	func updateHeaderSize(with walletViewController: WalletViewController, animated: Bool) {
		guard case let .fixed(_, menuHeight) = pagingViewController.menuItemSize else {
			return
		}
		
		let pagingHeight = menuHeight + walletViewController.height
		
		var headerBounds = accountHeaderView.bounds
		headerBounds.size.height = accountHeaderView.walletViewContainer.frame.origin.y + pagingHeight
		
		if animated {
			UIView.animate(withDuration: 0.2) { [unowned self] in
				self.accountHeaderView.bounds = headerBounds
				self.tableView.tableHeaderView = self.accountHeaderView
			}
		} else {
			accountHeaderView.frame = headerBounds
			tableView.tableHeaderView = accountHeaderView
		}
	}
}

extension AccountViewController: WalletViewControllerDelegate {
    func walletViewControllerSelectedRow(_ viewController: WalletViewControllerBase) {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        for vc in walletViewControllers {
            if vc != viewController, let indexPath = vc.tableView.indexPathForSelectedRow {
                vc.tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
