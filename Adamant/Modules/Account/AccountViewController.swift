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
import SnapKit
import CommonKit
import Combine

// MARK: - Localization
extension String.adamant {
    struct account {
        static let title = String.localized("AccountTab.Title", comment: "Account page: scene title")
        
        static let updatingBalance = "…"
        
        private init() { }
    }
}

extension String.adamant.alert {
    static let logoutMessageFormat = String.localized("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
    static let logoutButton = String.localized("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
}

// MARK: AccountViewController
final class AccountViewController: FormViewController {
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
            case .wallet: return "Wallet"    // Depends on selected wallet
            case .application: return .localized("AccountTab.Section.Application", comment: "Account tab: Application section title")
            case .actions: return .localized("AccountTab.Section.Actions", comment: "Account tab: Actions section title")
            case .delegates: return .localized("AccountTab.Section.Delegates", comment: "Account tab: Delegates section title")
            case .security: return Rows.security.localized
            }
        }
    }
    
    enum Rows {
        case balance, sendTokens // Wallet
        case security, nodes, theme, currency, about, visibleWallets, contribute, vibration // Application
        case voteForDelegates, generateQr, generatePk, logout // Actions
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
            case .generatePk: return "pk"
            case .stayIn: return "stayin"
            case .biometry: return "biometry"
            case .notifications: return "notifications"
            case .visibleWallets: return "visibleWallets"
            case .contribute: return "contribute"
            case .vibration: return "vibration"
            }
        }
        
        var localized: String {
            switch self {
            case .balance: return .localized("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
            case .sendTokens: return .localized("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
            case .security: return .localized("AccountTab.Row.Security", comment: "Account tab: 'Security' row")
            case .theme: return .localized("AccountTab.Row.Theme", comment: "Account tab: 'Theme' row")
            case .currency: return .localized("AccountTab.Row.Currency", comment: "Account tab: 'Currency' row")
            case .nodes: return String.adamant.nodesList.nodesListButton
            case .about: return .localized("AccountTab.Row.About", comment: "Account tab: 'About' row")
            case .logout: return .localized("AccountTab.Row.Logout", comment: "Account tab: 'Logout' button")
            case .voteForDelegates: return .localized("AccountTab.Row.VoteForDelegates", comment: "Account tab: 'Votes for delegates' button")
            case .generateQr: return .localized("SecurityPage.Row.GenerateQr", comment: "Security: Generate QR with passphrase row")
            case .generatePk: return .localized("SecurityPage.Row.GeneratePk", comment: "Security: Generate PrivateKey with passphrase row")
            case .stayIn: return SecurityViewController.Rows.stayIn.localized
            case .biometry: return SecurityViewController.Rows.biometry.localized
            case .notifications: return SecurityViewController.Rows.notificationsMode.localized
            case .visibleWallets: return .localized("VisibleWallets.Title", comment: "Visible Wallets page: scene title")
            case .contribute: return .localized("AccountTab.Row.Contribute", comment: "Account tab: 'Contribute' row")
            case .vibration: return "Vibrations"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .security: return .asset(named: "row_security")
            case .about: return .asset(named: "row_about")
            case .theme: return .asset(named: "row_themes.png")
            case .currency: return .asset(named: "row_currency")
            case .nodes: return .asset(named: "row_nodes")
            case .balance: return .asset(named: "row_balance")
            case .voteForDelegates: return .asset(named: "row_vote-delegates")
            case .logout: return .asset(named: "row_logout")
            case .sendTokens: return nil
            case .generateQr: return .asset(named: "row_QR.png")
            case .generatePk: return .asset(named: "privateKey_row")
            case .stayIn: return .asset(named: "row_security")
            case .biometry: return nil // Determined by localAuth service
            case .notifications: return .asset(named: "row_Notifications.png")
            case .visibleWallets: return .asset(named: "row_balance")
            case .contribute: return .asset(named: "row_contribute")
            case .vibration: return .asset(named: "row_contribute")
            }
        }
    }
    
    // MARK: - Dependencies
    var visibleWalletsService: VisibleWalletsService!
    var accountService: AccountService!
    var dialogService: DialogService!
    var screensFactory: ScreensFactory!
    var notificationsService: NotificationsService!
    var transfersProvider: TransfersProvider!
    var localAuth: LocalAuthentication!
    
    var avatarService: AvatarService!
    
    var currencyInfoService: CurrencyInfoService!
    
    // MARK: - Properties
    
    let walletCellIdentifier = "wllt"
    private (set) var accountHeaderView: AccountHeaderView!
    
    private var transfersController: NSFetchedResultsController<TransferTransaction>?
    private var pagingViewController: PagingViewController!
    
    private var initiated = false
    
    private var walletViewControllers = [WalletViewController]()
    private var notificationsSet: Set<AnyCancellable> = []
    
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
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .adamant.primary
        refreshControl.addTarget(self, action: #selector(self.handleRefresh(_:)), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationOptions = .Disabled
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .never
        
        // MARK: Status Bar
        let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        statusBarView.backgroundColor = UIColor.adamant.backgroundColor
        view.addSubview(statusBarView)
        
        // MARK: Transfers controller
        Task {
            let controller = await transfersProvider.unreadTransfersController()
            controller.delegate = self
            transfersController = controller
            
            do {
                try controller.performFetch()
            } catch {
                dialogService.showError(withMessage: "Error fetching transfers: report a bug", supportEmail: true, error: error)
            }
        }
        
        // MARK: Header&Footer
        guard let header = UINib(nibName: "AccountHeader", bundle: nil).instantiate(withOwner: nil, options: nil).first as? AccountHeaderView else {
            fatalError("Can't load AccountHeaderView")
        }
        
        accountHeaderView = header
        accountHeaderView.delegate = self
        
        updateAccountInfo()
        
        tableView.tableHeaderView = header
        
        tableView.refreshControl = self.refreshControl
        
        if let footer = UINib(nibName: "AccountFooter", bundle: nil).instantiate(withOwner: nil, options: nil).first as? UIView {
            tableView.tableFooterView = footer
        }
        
        // MARK: Wallet pages
        setupWalletsVC()
        
        pagingViewController = PagingViewController()
        pagingViewController.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), for: WalletPagingItem.self)
        pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
        pagingViewController.indicatorColor = UIColor.adamant.primary
        pagingViewController.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        if walletViewControllers.count > 0 {
            pagingViewController.select(index: 0)
        }
        
        accountHeaderView.walletViewContainer.addSubview(pagingViewController.view)
        pagingViewController.view.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        addChild(pagingViewController)
        
        updatePagingItemHeight()
        
        pagingViewController.borderColor = UIColor.clear
        
        let callback: ((Notification) -> Void) = { [weak self] _ in
            self?.pagingViewController.reloadData()
        }
        
        for walletService in accountService.wallets {
            NotificationCenter.default.addObserver(forName: walletService.walletUpdatedNotification, object: nil, queue: OperationQueue.main, using: callback)
        }
        
        // MARK: Rows&Sections
        
        // MARK: Application
        let appSection = Section(Sections.application.localized) {
            $0.tag = Sections.application.tag
        }
        
        // Visible wallets
        let visibleWalletsRow = LabelRow {
            $0.tag = Rows.visibleWallets.tag
            $0.title = Rows.visibleWallets.localized
            $0.cell.imageView?.image = Rows.visibleWallets.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeVisibleWallets()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                details.definesPresentationContext = true
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        appSection.append(visibleWalletsRow)
        
        // Node list
        let nodesRow = LabelRow {
            $0.title = Rows.nodes.localized
            $0.tag = Rows.nodes.tag
            $0.cell.imageView?.image = Rows.nodes.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeNodesList()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        appSection.append(nodesRow)
        
        // Currency select
        let currencyRow = ActionSheetRow<Currency> {
            $0.title = Rows.currency.localized
            $0.tag = Rows.currency.tag
            $0.cell.imageView?.image = Rows.currency.image
            $0.options = [Currency.USD, Currency.EUR, Currency.RUB, Currency.CNY, Currency.JPY]
            $0.value = currencyInfoService.currentCurrency
            
            $0.displayValueFor = { currency in
                guard let currency = currency else {
                    return nil
                }
                
                return "\(currency.rawValue) (\(currency.symbol))"
            }
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onChange { row in
            if let value = row.value {
                self.currencyInfoService.currentCurrency = value
            }
        }
        
        appSection.append(currencyRow)
        
        // Contribute
        let contributeRow = LabelRow {
            $0.title = Rows.contribute.localized
            $0.tag = Rows.contribute.tag
            $0.cell.imageView?.image = Rows.contribute.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeContribute()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController: vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        appSection.append(contributeRow)
        
        // About
        let aboutRow = LabelRow {
            $0.title = Rows.about.localized
            $0.tag = Rows.about.tag
            $0.cell.imageView?.image = Rows.about.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeAbout()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        appSection.append(aboutRow)
        
        // MARK: Actions
        let actionsSection = Section(Sections.actions.localized) {
            $0.tag = Sections.actions.tag
        }
        
        // Delegates
        let delegatesRow = LabelRow {
            $0.tag = Rows.voteForDelegates.tag
            $0.title = Rows.voteForDelegates.localized
            $0.cell.imageView?.image = Rows.voteForDelegates.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeDelegatesList()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                details.definesPresentationContext = true
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        actionsSection.append(delegatesRow)
        
        // Generate passphrase QR
        let generateQrRow = LabelRow {
            $0.title = Rows.generateQr.localized
            $0.tag = Rows.generateQr.tag
            $0.cell.imageView?.image = Rows.generateQr.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeQRGenerator()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        actionsSection.append(generateQrRow)
        
        // Generatte private keys
        let generatePkRow = LabelRow {
            $0.title = Rows.generatePk.localized
            $0.tag = Rows.generatePk.tag
            $0.cell.imageView?.image = Rows.generatePk.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makePKGenerator()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        actionsSection.append(generatePkRow)
        
        // Logout
        let logoutRow = LabelRow {
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
            
            let alert = UIAlertController(title: String.localizedStringWithFormat(String.adamant.alert.logoutMessageFormat, address), message: nil, preferredStyleSafe: .alert, source: nil)
            let cancel = UIAlertAction(title: String.adamant.alert.cancel, style: .cancel) { _ in
                guard let indexPath = row.indexPath else {
                    return
                }
                
                self?.tableView.deselectRow(at: indexPath, animated: true)
            }
            let logout = UIAlertAction(
                title: .adamant.alert.logoutButton,
                style: .default
            ) { [weak self] _ in
                guard let self = self else { return }
                accountService.logout()
                let vc = screensFactory.makeLogin()
                vc.modalPresentationStyle = .overFullScreen
                dialogService.present(vc, animated: true, completion: nil)
            }
            
            alert.addAction(cancel)
            alert.addAction(logout)
            alert.modalPresentationStyle = .overFullScreen
            self?.present(alert, animated: true, completion: nil)
        }
        
        actionsSection.append(logoutRow)
        
        // MARK: Security section
        
        let securitySection = Section(Sections.security.localized) {
            $0.tag = Sections.security.tag
        }
        
        // Stay in
        
        let stayInRow = SwitchRow {
            $0.tag = Rows.stayIn.tag
            $0.title = Rows.stayIn.localized
            $0.cell.imageView?.image = Rows.stayIn.image
            $0.value = accountService.hasStayInAccount
        }.cellUpdate { (cell, _) in
            cell.switchControl.onTintColor = UIColor.adamant.active
        }.onChange { [weak self] row in
            guard let enabled = row.value else {
                return
            }
            
            self?.setStayLoggedIn(enabled: enabled)
        }
        
        securitySection.append(stayInRow)
        
        // Biometry
        let biometryRow = SwitchRow { [weak self] in
            guard let self = self else { return }
            $0.tag = Rows.biometry.tag
            $0.title = localAuth.biometryType.localized
            $0.value = accountService.useBiometry
            
            if let auth = localAuth {
                switch auth.biometryType {
                case .none: $0.cell.imageView?.image = nil
                case .touchID: $0.cell.imageView?.image = .asset(named: "row_touchid.png")
                case .faceID: $0.cell.imageView?.image = .asset(named: "row_faceid.png")
                }
            }
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showBiometry = self?.showBiometryOptions else {
                    return true
                }
                
                return !showBiometry
            })
        }.cellUpdate { (cell, _) in
            cell.switchControl.onTintColor = UIColor.adamant.active
        }.onChange { [weak self] row in
            let value = row.value ?? false
            self?.setBiometry(enabled: value)
        }
        
        securitySection.append(biometryRow)
        
        // Notifications
        let notificationsRow = LabelRow { [weak self] in
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
            guard let self = self else { return }
            let vc = screensFactory.makeNotifications()
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                present(vc, animated: true, completion: nil)
            }
            
            deselectWalletViewControllers()
        }
        
        securitySection.append(notificationsRow)
        
        // MARK: Appending sections
        form.append(securitySection)
        form.append(actionsSection)
        form.append(appSection)
        
        form.allRows.forEach { $0.baseCell.imageView?.tintColor = UIColor.adamant.tableRowIcons }
        
        // MARK: Notification Center
        addObservers()
        
        setColors()
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
            if !initiated {
                initiated = true
            }
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
    
    func addObservers() {
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else { return }
            
            self.updateAccountInfo()
            self.tableView.setContentOffset(
                CGPoint(
                    x: .zero,
                    y: -self.tableView.frame.size.height
                ),
                animated: false
            )
            
            self.pagingViewController.reloadData()
            self.tableView.reloadData()
            if let vc = self.pagingViewController.pageViewController.selectedViewController as? WalletViewController {
                self.updateHeaderSize(with: vc, animated: false)
            }
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateAccountInfo()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.accountDataUpdated, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateAccountInfo()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.stayInChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
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
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantVisibleWalletsService.visibleWallets, object: nil, queue: OperationQueue.main) { [weak self] _ in
            guard let self = self else { return }
            
            self.setupWalletsVC()
            self.updatePagingItemHeight()
            
            self.pagingViewController.reloadData()
            let collectionView = self.pagingViewController.collectionView
            collectionView.reloadData()
            self.tableView.reloadData()
        }
        
        for vc in walletViewControllers {
            guard let service = vc.service else { return }
            let notification = service.walletUpdatedNotification
            let callback: ((Notification) -> Void) = { [weak self] _ in
                guard let self = self else { return }
                let collectionView = self.pagingViewController.collectionView
                collectionView.reloadData()
            }

            NotificationCenter.default.addObserver(forName: notification,
                                                   object: service,
                                                   queue: OperationQueue.main,
                                                   using: callback)
        }
        
        NotificationCenter.default
            .publisher(for: .AdamantVibroService.presentVibrationRow)
            .sink { [weak self] _ in
                self?.addVibrationRow()
            }
            .store(in: &notificationsSet)
    }
    
    private func setupWalletsVC() {
        walletViewControllers.removeAll()
        let availableServices: [WalletService] = visibleWalletsService.sorted(includeInvisible: false)
        availableServices.forEach { walletService in
            walletViewControllers.append(screensFactory.makeWalletVC(service: walletService))
        }
    }
    
    private func updatePagingItemHeight() {
        if walletViewControllers.count > 0 {
            pagingViewController.menuItemSize = .fixed(width: 110, height: 114)
        } else {
            pagingViewController.menuItemSize = .fixed(width: 110, height: 0)
        }
        
        updateHeaderSize(with: pagingViewController.menuItemSize.height, animated: true)
    }
    
    private func setColors() {
        view.backgroundColor = .adamant.secondBackgroundColor
        pagingViewController.backgroundColor = .adamant.backgroundColor
        pagingViewController.menuBackgroundColor = .adamant.backgroundColor
        pagingViewController.view.backgroundColor = .adamant.backgroundColor
        pagingViewController.reloadData()
        tableView.backgroundColor = .clear
        accountHeaderView.backgroundColor = .adamant.backgroundColor
    }
    
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

        let width = view.bounds.size.width
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
        for controller in walletViewControllers {
            guard let vc = controller.viewController as? WalletViewControllerBase else {
                continue
            }
            
            // ViewController can be not yet initialized
            if let tableView = vc.tableView, let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        refreshControl.endRefreshing()
        DispatchQueue.background.async {
            self.accountService.reloadWallets()
        }
    }
    
    private func addVibrationRow() {
        guard let appSection = form.sectionBy(tag: Sections.application.tag)
        else { return }
        
        let vibrationRow = LabelRow {
            $0.title = Rows.vibration.localized
            $0.tag = Rows.vibration.tag
            $0.cell.imageView?.image = Rows.vibration.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let vc = self?.screensFactory.makeVibrationSelection()
            else {
                return
            }
            
            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else if let nav = self?.navigationController {
                nav.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .overFullScreen
                self?.present(vc, animated: true, completion: nil)
            }
            
            self?.deselectWalletViewControllers()
        }
        
        appSection.append(vibrationRow)
    }
}

// MARK: - AccountHeaderViewDelegate
extension AccountViewController: AccountHeaderViewDelegate {
    func addressLabelTapped(from: UIView) {
        guard let address = accountService.account?.address else {
            return
        }
        
        let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
        dialogService.presentShareAlertFor(stringForPasteboard: address,
                                           stringForShare: encodedAddress,
                                           stringForQR: encodedAddress,
                                           types: [.copyToPasteboard,
                                                   .share,
                                                   .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)
                                                  ],
                                           excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                           animated: true,
                                           from: from,
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
    func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        return walletViewControllers.count
    }
    
    func pagingViewController(_ pagingViewController: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return walletViewControllers[index].viewController
    }

    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        guard let service = walletViewControllers[index].service else {
            return WalletPagingItem(
                index: index,
                currencySymbol: "",
                currencyImage: .asset(named: "adamant_wallet") ?? .init(),
                isBalanceInitialized: false)
        }
        
        var network = ""
        if ERC20Token.supportedTokens.contains(where: { token in
            return token.symbol == service.tokenSymbol
        }) {
            network = service.tokenNetworkSymbol
        }
        
        let item = WalletPagingItem(
            index: index,
            currencySymbol: service.tokenSymbol,
            currencyImage: service.tokenLogo,
            isBalanceInitialized: service.wallet?.isBalanceInitialized,
            currencyNetwork: network)
        
        if let wallet = service.wallet {
            item.balance = wallet.balance
            item.notifications = wallet.notifications
        } else {
            item.balance = nil
        }
        
        return item
    }
    
    func pagingViewController(_ pagingViewController: PagingViewController, didScrollToItem pagingItem: PagingItem, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) {
        guard transitionSuccessful,
            let first = startingViewController as? WalletViewController,
            let second = destinationViewController as? WalletViewController,
            first.height != second.height else {
            return
        }

        updateHeaderSize(with: second, animated: true)
    }
    
    private func updateHeaderSize(with walletViewController: WalletViewController, animated: Bool) {
        guard case let .fixed(_, menuHeight) = pagingViewController.menuItemSize else {
            return
        }
        let pagingHeight = menuHeight + walletViewController.height
        
        updateHeaderSize(with: pagingHeight, animated: animated)
    }
    
    private func updateHeaderSize(with pagingHeight: CGFloat, animated: Bool) {
        var headerBounds = accountHeaderView.bounds
        headerBounds.size.height = accountHeaderView.walletViewContainer.frame.origin.y + pagingHeight
        
        if animated {
            UIView.animate(withDuration: 0.2) {
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
        
        for controller in walletViewControllers {
            guard controller.viewController != viewController, let vc = controller.viewController as? WalletViewControllerBase else {
                continue
            }
            
            // Better check it
            if let tableView = vc.tableView, let indexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}
