//
//  WalletViewControllerBase.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import CommonKit
import Combine

extension String.adamant {
    struct wallets {
        
        private init() {}
    }
}

protocol WalletViewControllerDelegate: AnyObject {
    func walletViewControllerSelectedRow(_ viewController: WalletViewControllerBase)
}

class WalletViewControllerBase: FormViewController, WalletViewController {
    // MARK: - Rows
    enum BaseRows {
        case address, balance, send
        
        var tag: String {
            switch self {
            case .address: return "a"
            case .balance: return "b"
            case .send: return "s"
            }
        }
        
        var localized: String {
            switch self {
            case .address: return .localized("AccountTab.Row.Address", comment: "Account tab: 'Address' row")
            case .balance: return .localized("AccountTab.Row.Balance", comment: "Account tab: Balance row title")
            case .send: return .localized("AccountTab.Row.SendTokens", comment: "Account tab: 'Send tokens' button")
            }
        }
    }
    
    private let cellIdentifier = "cell"
    
    // MARK: - Dependencies
    
    private let currencyInfoService: InfoServiceProtocol
    private let accountService: AccountService
    private let walletServiceCompose: WalletServiceCompose
    
    let dialogService: DialogService
    let screensFactory: ScreensFactory
    var service: WalletService?

    // MARK: - Properties, WalletViewController
    
    var viewController: UIViewController { return self }
    var height: CGFloat { tableView.contentSize.height + additionalSpace }
        
    weak var delegate: WalletViewControllerDelegate?
    
    private lazy var fiatFormatter: NumberFormatter = {
        return AdamantBalanceFormat.fiatFormatter(for: currencyInfoService.currentCurrency)
    }()
    
    private var subscriptions = Set<AnyCancellable>()
    private let headerHeight: CGFloat = 2
    private let additionalSpace: CGFloat = 5
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var walletTitleLabel: UILabel!
    @IBOutlet weak var initiatingActivityIndicator: UIActivityIndicatorView!
    
    // MARK: Error view
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: Init
    
    init(
        dialogService: DialogService,
        currencyInfoService: InfoServiceProtocol,
        accountService: AccountService,
        screensFactory: ScreensFactory,
        walletServiceCompose: WalletServiceCompose,
        service: WalletService?
    ) {
        self.dialogService = dialogService
        self.currencyInfoService = currencyInfoService
        self.accountService = accountService
        self.screensFactory = screensFactory
        self.walletServiceCompose = walletServiceCompose
        self.service = service
        super.init(nibName: "WalletViewControllerBase", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitle()
        addObservers()
        
        let section = Section()
        // MARK: Address
        let addressRow = adressRow()
        
        section.append(addressRow)
        
        // MARK: Balance
        let balanceRow = BalanceRow { [weak self] in
            $0.tag = BaseRows.balance.tag
            $0.cell.titleLabel.text = BaseRows.balance.localized
            
            $0.alertBackgroundColor = UIColor.adamant.primary
            $0.alertTextColor = UIColor.adamant.cellAlertTextColor
            $0.cell.backgroundColor = UIColor.adamant.cellColor
            let symbol = self?.service?.core.tokenSymbol ?? ""
            
            $0.value = self?.balanceRowValueFor(
                balance: self?.service?.core.wallet?.balance ?? 0,
                symbol: symbol,
                alert: self?.service?.core.wallet?.notifications,
                isBalanceInitialized: self?.service?.core.wallet?.isBalanceInitialized ?? false
            )
            
            let height = $0.value?.fiat != nil ? BalanceTableViewCell.fullHeight : BalanceTableViewCell.compactHeight
            
            $0.cell.height = { height }
        }.cellUpdate { [weak self] (cell, row) in
            let symbol = self?.service?.core.tokenSymbol ?? ""
            
            row.value = self?.balanceRowValueFor(
                balance: self?.service?.core.wallet?.balance ?? 0,
                symbol: symbol,
                alert: self?.service?.core.wallet?.notifications,
                isBalanceInitialized: self?.service?.core.wallet?.isBalanceInitialized ?? false
            )
            
            let height = row.value?.fiat != nil ? BalanceTableViewCell.fullHeight : BalanceTableViewCell.compactHeight
            
            cell.height = { height }
            cell.titleLabel.text = BaseRows.balance.localized
        }
        
        balanceRow.cell.selectionStyle = .gray
        balanceRow.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
            cell.titleLabel.text = BaseRows.balance.localized
        }.onCellSelection { [weak self] (_, _) in
            guard
                let self = self,
                let service = service
            else { return }
            
            let vc = screensFactory.makeTransferListVC(service: service)
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else {
                navigationController?.pushViewController(vc, animated: true )
            }
            
            if let delegate = delegate {
                delegate.walletViewControllerSelectedRow(self)
            }
        }
        
        section.append(balanceRow)
        
        // MARK: Send
        
        let label = sendRowLocalizedLabel()
        
        let sendRow = LabelRow {
            $0.tag = BaseRows.send.tag
            var content = $0.cell.defaultContentConfiguration()
            content.attributedText = label
            $0.cell.contentConfiguration = content
            $0.cell.selectionStyle = .gray
            $0.cell.backgroundColor = UIColor.adamant.cellColor
        }.cellUpdate { [weak self] (cell, _) in
            cell.accessoryType = .disclosureIndicator
            
            cell.separatorInset = self?.service?.core is AdmWalletService
            ? UITableView.defaultSeparatorInset
            : .zero
            
            let label = self?.sendRowLocalizedLabel()
            var content = cell.defaultContentConfiguration()
            content.attributedText = label
            cell.contentConfiguration = content
        }.onCellSelection { [weak self] (_, _) in
            guard let self = self, let service = service else { return }
            
            let vc = screensFactory.makeTransferVC(service: service)
            vc.delegate = self
            if ERC20Token.supportedTokens.contains(where: { token in
                return token.symbol == service.core.tokenSymbol
            }) {
                
                let ethWallet = walletServiceCompose.getWallet(
                    by: EthWalletService.richMessageType
                )?.core
                
                vc.rootCoinBalance = ethWallet?.wallet?.balance
            }
            
            if let split = splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else {
                if let nav = navigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    vc.modalPresentationStyle = .overFullScreen
                    present(vc, animated: true)
                }
            }
            
            if let delegate = delegate {
                delegate.walletViewControllerSelectedRow(self)
            }
        }
        
        section.append(sendRow)
        
        form.append(section)
        
        if let state = service?.core.state {
            setUiToWalletServiceState(state)
        } else {
            setUiToWalletServiceState(.notInitiated)
        }
        
        setColors()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
    
    override func viewDidLayoutSubviews() {
        NotificationCenter.default.post(name: Notification.Name.WalletViewController.heightUpdated, object: self)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return headerHeight
    }
    // MARK: - To override
    
    func sendRowLocalizedLabel() -> NSAttributedString {
        return NSAttributedString(string: BaseRows.send.localized)
    }
    
    func encodeForQr(address: String) -> String? {
        return nil
    }
    
    func includeLogoInQR() -> Bool {
        return false
    }
    
    func adressRow() -> LabelRow {
        let addressRow = LabelRow {
            $0.tag = BaseRows.address.tag
            $0.title = BaseRows.address.localized
            $0.cell.selectionStyle = .gray
            $0.cell.backgroundColor = UIColor.adamant.cellColor
            $0.cell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle
            if let wallet = service?.core.wallet {
                $0.value = wallet.address
            }
        }.cellUpdate { (cell, row) in
            cell.accessoryType = .disclosureIndicator
            row.title = BaseRows.address.localized
        }.onCellSelection { [weak self] (cell, row) in
            row.deselect()
            let completion = { [weak self] in
                guard let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow else {
                    return
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            if let address = self?.service?.core.wallet?.address {
                let types: [ShareType]
                let withLogo = self?.includeLogoInQR() ?? false
                
                if let encodedAddress = self?.encodeForQr(address: address) {
                    types = [.copyToPasteboard, .share, .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: withLogo)]
                } else {
                    types = [.copyToPasteboard, .share]
                }
                
                self?.dialogService.presentShareAlertFor(string: address,
                                                         types: types,
                                                         excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                         animated: true,
                                                         from: cell,
                                                         completion: completion)
            }
        }
        return addressRow
    }
    
    func setTitle() { }
    
    // MARK: - Other
    
    private var currentUiState: WalletServiceState = .upToDate
    
    func setUiToWalletServiceState(_ state: WalletServiceState) {
        guard currentUiState != state else {
            return
        }
        
        switch state {
        case .upToDate, .updating:
            initiatingActivityIndicator.stopAnimating()
            tableView.isHidden = false
            errorView.isHidden = true
            
        case .notInitiated:
            initiatingActivityIndicator.startAnimating()
            tableView.isHidden = true
            errorView.isHidden = true
            
        case .initiationFailed(let reason):
            initiatingActivityIndicator.stopAnimating()
            tableView.isHidden = true
            errorView.isHidden = false
            errorLabel.text = reason
        }
        
        currentUiState = state
    }
    
    private func balanceRowValueFor(
        balance: Decimal,
        symbol: String?,
        alert: Int?,
        isBalanceInitialized: Bool
    ) -> BalanceRowValue {
        let cryptoString = isBalanceInitialized
        ? AdamantBalanceFormat.full.format(balance, withCurrencySymbol: symbol)
        : String.adamant.account.updatingBalance
        
        let fiatString: String?
        if balance > 0, let symbol = symbol, let rate = currencyInfoService.getRate(for: symbol) {
            let fiat = balance * rate
            fiatString = fiatFormatter.string(from: fiat)
        } else {
            fiatString = nil
        }
        
        if let alert = alert, alert > 0 {
            return BalanceRowValue(crypto: cryptoString, fiat: fiatString, alert: alert)
        } else {
            return BalanceRowValue(crypto: cryptoString, fiat: fiatString, alert: nil)
        }
    }
    
    private func stringFor(balance: Decimal, symbol: String?) -> String {
        var value = AdamantBalanceFormat.full.format(balance, withCurrencySymbol: symbol)
        
        if balance > 0, let symbol = symbol, let rate = currencyInfoService.getRate(for: symbol) {
            let fiat = balance * rate
            let fiatString = AdamantBalanceFormat.short.format(fiat, withCurrencySymbol: currencyInfoService.currentCurrency.symbol)
            
            value = "\(value) (\(fiatString))"
        }
        
        return value
    }
    
    // MARK: - Other
    
    func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
        initiatingActivityIndicator.color = .adamant.primary
    }
}

private extension WalletViewControllerBase {
    func addObservers() {
        guard let service = service else { return }
        
        NotificationCenter.default
            .publisher(for: service.core.serviceStateChanged)
            .receive(on: OperationQueue.main)
            .sink { [weak self] notification in
                guard let newState = notification.userInfo?[AdamantUserInfoKey.WalletService.walletState] as? WalletServiceState
                else { return }
                
                self?.setUiToWalletServiceState(newState)
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: service.core.walletUpdatedNotification)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.updateWalletUI()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .AdamantCurrencyInfoService.currencyRatesUpdated)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.updateWalletUI()
            }
            .store(in: &subscriptions)
        
        NotificationCenter.default
            .publisher(for: .LanguageStorageService.languageUpdated)
            .receive(on: OperationQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
                self?.setTitle()
            }
            .store(in: &subscriptions)
    }
    
    func updateWalletUI() {
        guard let service = service else { return }
        
        if let row: LabelRow = form.rowBy(tag: BaseRows.address.tag) {
            if let wallet = service.core.wallet {
                row.value = wallet.address
                row.updateCell()
            }
        }
        
        guard let wallet = service.core.wallet,
              let row: BalanceRow = form.rowBy(tag: BaseRows.balance.tag)
        else { return }
        
        fiatFormatter.currencyCode = currencyInfoService.currentCurrency.rawValue
        
        let symbol = service.core.tokenSymbol
        row.value = balanceRowValueFor(
            balance: wallet.balance,
            symbol: symbol,
            alert: wallet.notifications,
            isBalanceInitialized: wallet.isBalanceInitialized
        )
        row.updateCell()
    }
}

// MARK: - TransferViewControllerDelegate
extension WalletViewControllerBase: TransferViewControllerDelegate {
    func transferViewController(
        _ viewController: TransferViewControllerBase,
        didFinishWithTransfer transfer: TransactionDetails?,
        detailsViewController: UIViewController?
    ) {
        DispatchQueue.onMainAsync { [self] in
            if let split = splitViewController {
                if let nav = split.viewControllers.last as? UINavigationController {
                    if let detailsViewController = detailsViewController {
                        var viewControllers = nav.viewControllers
                        viewControllers.removeLast()
                        
                        if let service = service {
                            viewControllers.append(screensFactory.makeTransferListVC(service: service))
                        }
                        
                        viewControllers.append(detailsViewController)
                        nav.setViewControllers(viewControllers, animated: true)
                    } else {
                        nav.popViewController(animated: true)
                    }
                } else {
                    split.showDetailViewController(viewController, sender: nil)
                }
            } else if let nav = navigationController {
                if let detailsViewController = detailsViewController {
                    var viewControllers = nav.viewControllers
                    viewControllers.removeLast()
                    viewControllers.append(detailsViewController)
                    nav.setViewControllers(viewControllers, animated: true)
                } else {
                    nav.popViewController(animated: true)
                }
            } else if presentedViewController == viewController {
                dismiss(animated: true, completion: nil)
                
                if let detailsViewController = detailsViewController {
                    detailsViewController.modalPresentationStyle = .overFullScreen
                    present(detailsViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
