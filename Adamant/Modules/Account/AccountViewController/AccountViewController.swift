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
@preconcurrency import CoreData
@preconcurrency import Parchment
import SnapKit
import CommonKit
import Combine

// MARK: - Localization
extension String.adamant {
    enum account {
        static var title: String {
            String.localized("AccountTab.Title", comment: "Account page: scene title")
        }
        
        static let updatingBalance = "…"
    }
}

extension String.adamant.alert {
    static var logoutMessageFormat: String { String.localized("AccountTab.ConfirmLogout.MessageFormat", comment: "Account tab: Confirm logout alert")
    }
    static var logoutButton: String { String.localized("AccountTab.ConfirmLogout.Logout", comment: "Account tab: Confirm logout alert: Logout (Ok) button")
    }
}

// MARK: AccountViewController
final class AccountViewController: FormViewController {
    // MARK: - Dependencies
    
    private let visibleWalletsService: VisibleWalletsService
    private let screensFactory: ScreensFactory
    private let notificationsService: NotificationsService
    private let transfersProvider: TransfersProvider
    private let avatarService: AvatarService
    private let currencyInfoService: InfoServiceProtocol
    private let languageService: LanguageStorageProtocol
    private let apiServiceCompose: ApiServiceComposeProtocol
    private lazy var viewModel: AccountWalletsViewModel = .init(walletsService: visibleWalletsService)
    
    let accountService: AccountService
    let dialogService: DialogService
    let localAuth: LocalAuthentication
    
    // MARK: - Properties
    
    let walletCellIdentifier = "wllt"
    private(set) var accountHeaderView: AccountHeaderView!
    
    private var transfersController: NSFetchedResultsController<TransferTransaction>?
    private var pagingViewController: PagingViewController!
    
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
    
    private var walletViewControllers: [WalletViewController] = []
    
    private var currentWalletIndex: Int = .zero
    private var currentSelectedWalletItem: WalletCollectionViewCell.Model? {
        viewModel.state.wallets.first { wallet in
            wallet.index == currentWalletIndex
        }
    }
    
    private var initiated = false
    
    // MARK: - Init
    
    init(
        visibleWalletsService: VisibleWalletsService,
        accountService: AccountService,
        dialogService: DialogService,
        screensFactory: ScreensFactory,
        notificationsService: NotificationsService,
        transfersProvider: TransfersProvider,
        localAuth: LocalAuthentication,
        avatarService: AvatarService,
        currencyInfoService: InfoServiceProtocol,
        languageService: LanguageStorageProtocol,
        walletServiceCompose: WalletServiceCompose,
        apiServiceCompose: ApiServiceComposeProtocol
    ) {
        self.visibleWalletsService = visibleWalletsService
        self.accountService = accountService
        self.dialogService = dialogService
        self.screensFactory = screensFactory
        self.notificationsService = notificationsService
        self.transfersProvider = transfersProvider
        self.localAuth = localAuth
        self.avatarService = avatarService
        self.currencyInfoService = currencyInfoService
        self.languageService = languageService
        self.apiServiceCompose = apiServiceCompose
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        let footerView = AccountFooterView(frame: CGRect(x: .zero, y: .zero, width: self.view.frame.width, height: 100))
        tableView.tableFooterView = footerView
        
        // MARK: Wallet pages
        setupWalletsVC()
        
        pagingViewController = PagingViewController()
        pagingViewController.register(UINib(nibName: "WalletCollectionViewCell", bundle: nil), for: WalletCollectionViewCell.Model.self)
        pagingViewController.menuItemSize = .fixed(width: 110, height: 110)
        pagingViewController.indicatorColor = UIColor.adamant.primary
        pagingViewController.indicatorOptions = .visible(height: 2, zIndex: Int.max, spacing: UIEdgeInsets.zero, insets: UIEdgeInsets.zero)
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        if walletViewControllers.count > 0 {
            pagingViewController.select(index: currentWalletIndex)
        }
        
        accountHeaderView.walletViewContainer.addSubview(pagingViewController.view)
        pagingViewController.view.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        addChild(pagingViewController)
        
        updatePagingItemHeight()
        
        pagingViewController.borderColor = UIColor.clear
        
        viewModel.$state
            .removeDuplicates(by: { old, new in
                old.wallets == new.wallets
            })
            .sink { [weak self] _ in
                MainActor.assumeIsolatedSafe {
                    guard let self = self else { return }
                    self.pagingViewController.reloadMenu()
                }
            }
            .store(in: &notificationsSet)
        
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.visibleWallets.localized
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.nodes.localized
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
        
        // Coins nodes list
        let coinsNodesRow = LabelRow {
            $0.title = Rows.coinsNodes.localized
            $0.tag = Rows.coinsNodes.tag
            $0.cell.imageView?.image = Rows.coinsNodes.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.coinsNodes.localized
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeCoinsNodesList(context: .menu)
            
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
        
        appSection.append(coinsNodesRow)
        
        // Language select
        let languageRow = ActionSheetRow<Language> {
            $0.title = Rows.language.localized
            $0.tag = Rows.language.tag
            $0.cell.imageView?.image = Rows.language.image
            $0.options = Language.all
            $0.value = languageService.getLanguage()
            
            $0.displayValueFor = { language in
                return language?.name
            }
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.language.localized
        }.onChange { [weak self] row in
            guard let value = row.value else { return }
            self?.languageService.setLanguage(value)
            self?.updateUI()
        }
        
        appSection.append(languageRow)
        
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.currency.localized
        }.onChange { [weak self] row in
            guard let value = row.value else { return }
            self?.currencyInfoService.currentCurrency = value
        }
        
        appSection.append(currencyRow)
        
        // Contribute
        let contributeRow = LabelRow {
            $0.title = Rows.contribute.localized
            $0.tag = Rows.contribute.tag
            $0.cell.imageView?.image = Rows.contribute.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.contribute.localized
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
        
        // Storage Usage
        let storageRow = LabelRow {
            $0.title = Rows.storage.localized
            $0.tag = Rows.storage.tag
            $0.cell.imageView?.image = Rows.storage.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.storage.localized
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self else { return }
            let vc = screensFactory.makeStorageUsage()
            
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
        
        appSection.append(storageRow)
        
        // About
        let aboutRow = LabelRow {
            $0.title = Rows.about.localized
            $0.tag = Rows.about.tag
            $0.cell.imageView?.image = Rows.about.image
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.about.localized
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.voteForDelegates.localized
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.generateQr.localized
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.generatePk.localized
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
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.logout.localized
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
                self.accountService.logout()
                let vc = self.screensFactory.makeLogin()
                vc.modalPresentationStyle = .overFullScreen
                self.dialogService.present(vc, animated: true, completion: nil)
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
        }.cellUpdate { (cell, row) in
            cell.switchControl.onTintColor = UIColor.adamant.active
            row.title = Rows.stayIn.localized
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
            
            switch localAuth.biometryType {
            case .none: $0.cell.imageView?.image = nil
            case .touchID: $0.cell.imageView?.image = .asset(named: "row_touchid.png")
            case .faceID: $0.cell.imageView?.image = .asset(named: "row_faceid.png")
            }
            
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                guard let showBiometry = self?.showBiometryOptions else {
                    return true
                }
                
                return !showBiometry
            })
        }.cellUpdate { [weak self] (cell, row) in
            cell.switchControl.onTintColor = UIColor.adamant.active
            row.title = self?.localAuth.biometryType.localized
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
        }.cellUpdate { [weak self] (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = Rows.notifications.localized
            row.value = self?.notificationsService.notificationsMode.localized
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
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantAccountService.userLoggedIn,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
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
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantAccountService.userLoggedOut,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
                self?.updateAccountInfo()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantAccountService.accountDataUpdated,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
                self?.updateAccountInfo()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantAccountService.stayInChanged,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
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
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantNotificationService.notificationsModeChanged,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            MainActor.assumeIsolatedSafe {
                guard let newMode = notification.userInfo?[AdamantUserInfoKey.NotificationsService.newNotificationsMode] as? NotificationsMode else {
                    return
                }
                
                guard let row: LabelRow = self?.form.rowBy(tag: Rows.notifications.tag) else {
                    return
                }
                
                row.value = newMode.localized
                row.updateCell()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.WalletViewController.heightUpdated,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] notification in
            MainActor.assumeIsolatedSafe {
                guard
                    let vc = notification.object as? WalletViewController,
                    let cvc = self?.pagingViewController.pageViewController.selectedViewController,
                    vc.viewController == cvc
                else { return }
                
                if let initiated = self?.initiated {
                    self?.updateHeaderSize(with: vc, animated: initiated)
                } else {
                    self?.updateHeaderSize(with: vc, animated: false)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantVisibleWalletsService.visibleWallets,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            MainActor.assumeIsolatedSafe {
                guard let self = self else { return }
                
                self.setupWalletsVC()
                self.viewModel.updateState()
                self.updatePagingItemHeight()
                
                self.pagingViewController.reloadData()
                let collectionView = self.pagingViewController.collectionView
                collectionView.reloadData()
                self.tableView.reloadData()
            }
        }
    }
    
    private func updateUI() {
        let appSection = form.sectionBy(tag: Sections.application.tag)
        appSection?.header?.title = Sections.application.localized

        let walletSection = form.sectionBy(tag: Sections.wallet.tag)
        walletSection?.header?.title = Sections.wallet.localized
        
        let securitySection = form.sectionBy(tag: Sections.security.tag)
        securitySection?.header?.title = Sections.security.localized
        
        let actionsSection = form.sectionBy(tag: Sections.actions.tag)
        actionsSection?.header?.title = Sections.actions.localized
        
        tableView.reloadData()
        
        tabBarController?.viewControllers?.first?.tabBarItem.title = .adamant.tabItems.chats
        tabBarController?.viewControllers?.last?.tabBarItem.title = .adamant.tabItems.account
        
        if let splitVC = tabBarController?.viewControllers?.first as? UISplitViewController,
           !splitVC.isCollapsed {
            splitVC.showDetailViewController(WelcomeViewController(), sender: nil)
        }
        
        if let splitVC = tabBarController?.viewControllers?.last as? UISplitViewController,
           !splitVC.isCollapsed {
            splitVC.showDetailViewController(WelcomeViewController(), sender: nil)
        }
    }
    
    private func setupWalletsVC() {
        walletViewControllers.removeAll()
        let availableServices = visibleWalletsService.sorted(includeInvisible: false)
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
            DispatchQueue.global().async { [avatarService] in
                let image = avatarService.avatar(for: publickey, size: 200)
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
        let unavailableNodes: [NodeGroup] = NodeGroup.allCases.filter {
            apiServiceCompose.get($0)?.hasEnabledNode == false
        }
        
        if unavailableNodes.contains(where: {
            $0.name == currentSelectedWalletItem?.currencyNetwork
        }) {
            dialogService.showWarning(
                withMessage: ApiServiceError.noEndpointsAvailable(
                    nodeGroupName: currentSelectedWalletItem?.currencyNetwork ?? ""
                ).localizedDescription
            )
        }
        
        refreshControl.endRefreshing()
        DispatchQueue.background.async { [accountService] in
            accountService.reloadWallets()
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
    nonisolated func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        Task { @MainActor in
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
}

// MARK: - PagingViewControllerDataSource
extension AccountViewController: PagingViewControllerDataSource, PagingViewControllerDelegate {
    nonisolated func numberOfViewControllers(in pagingViewController: PagingViewController) -> Int {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            walletViewControllers.count
        }
    }
    
    nonisolated func pagingViewController(
        _ pagingViewController: PagingViewController,
        viewControllerAt index: Int
    ) -> UIViewController {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            walletViewControllers[index].viewController
        }
    }

    nonisolated func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        MainActor.assertIsolated()
        
        return DispatchQueue.onMainThreadSyncSafe {
            return viewModel.state.wallets[safe: index] ?? WalletCollectionViewCell.Model.default
        }
    }
    
    nonisolated func pagingViewController(
        _ pagingViewController: PagingViewController,
        didScrollToItem pagingItem: PagingItem,
        startingViewController: UIViewController?,
        destinationViewController: UIViewController,
        transitionSuccessful: Bool
    ) {
        DispatchQueue.onMainThreadSyncSafe {
            guard transitionSuccessful,
                  let first = startingViewController as? WalletViewController,
                  let second = destinationViewController as? WalletViewController,
                  first.height != second.height else {
                return
            }

            updateHeaderSize(with: second, animated: true)
        }
    }
    
    nonisolated func pagingViewController(
        _ pagingViewController: PagingViewController,
        didSelectItem pagingItem: PagingItem
    ) {
        Task { @MainActor in
            currentWalletIndex = pagingItem.identifier
        }
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
