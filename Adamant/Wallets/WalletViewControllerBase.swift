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
    
    var dialogService: DialogService!
    var currencyInfoService: CurrencyInfoService!
    var walletsManager: WalletServicesManager!
    
    // MARK: - Properties, WalletViewController
    
    var viewController: UIViewController { return self }
    var height: CGFloat { return tableView.frame.origin.y + tableView.contentSize.height }
    
    var service: WalletService?
    
    weak var delegate: WalletViewControllerDelegate?
    
    private lazy var fiatFormatter: NumberFormatter = {
        return AdamantBalanceFormat.fiatFormatter(for: currencyInfoService.currentCurrency)
    }()
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var walletTitleLabel: UILabel!
    @IBOutlet weak var initiatingActivityIndicator: UIActivityIndicatorView!
    
    // MARK: Error view
    
    @IBOutlet weak var errorView: UIView!
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
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
            let symbol = self?.service?.tokenSymbol ?? ""
            
            $0.value = self?.balanceRowValueFor(
                balance: self?.service?.wallet?.balance ?? 0,
                symbol: symbol,
                alert: self?.service?.wallet?.notifications,
                isBalanceInitialized: self?.service?.wallet?.isBalanceInitialized ?? false
            )
            
            let height = $0.value?.fiat != nil ? BalanceTableViewCell.fullHeight : BalanceTableViewCell.compactHeight
            
            $0.cell.height = { height }
        }.cellUpdate { [weak self] (cell, row) in
            let symbol = self?.service?.tokenSymbol ?? ""
            
            row.value = self?.balanceRowValueFor(
                balance: self?.service?.wallet?.balance ?? 0,
                symbol: symbol,
                alert: self?.service?.wallet?.notifications,
                isBalanceInitialized: self?.service?.wallet?.isBalanceInitialized ?? false
            )
            
            let height = row.value?.fiat != nil ? BalanceTableViewCell.fullHeight : BalanceTableViewCell.compactHeight
            
            cell.height = { height }
        }
        
        if service is WalletServiceWithTransfers {
            balanceRow.cell.selectionStyle = .gray
            balanceRow.cellUpdate { (cell, _) in
                cell.accessoryType = .disclosureIndicator
            }.onCellSelection { [weak self] (_, _) in
                guard let service = self?.service as? WalletServiceWithTransfers else {
                    return
                }
                
                let vc = service.transferListViewController()
                if let split = self?.splitViewController {
                    let details = UINavigationController(rootViewController:vc)
                    split.showDetailViewController(details, sender: self)
                } else {
                    self?.navigationController?.pushViewController(vc, animated: true )
                }
                
                if let vc = self, let delegate = vc.delegate {
                    delegate.walletViewControllerSelectedRow(vc)
                }
            }
        }
        
        section.append(balanceRow)
        
        // MARK: Send
        if service is WalletServiceWithSend {
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
                
                cell.separatorInset = self?.service is AdmWalletService
                ? UITableView.defaultSeparatorInset
                : .zero
                
                if #unavailable(iOS 14.0) {
                    cell.textLabel?.attributedText = label
                }
            }.onCellSelection { [weak self] (_, _) in
                guard let service = self?.service as? WalletServiceWithSend else {
                    return
                }
                
                let vc = service.transferViewController()
                if let v = vc as? TransferViewControllerBase {
                    v.delegate = self
                    if ERC20Token.supportedTokens.contains(where: { token in
                        return token.symbol == service.tokenSymbol
                    }) {
                        v.rootCoinBalance = self?.walletsManager.ethWalletService.wallet?.balance
                    }
                }
                
                if let split = self?.splitViewController {
                    let details = UINavigationController(rootViewController:vc)
                    split.showDetailViewController(details, sender: self)
                } else {
                    if let nav = self?.navigationController {
                        nav.pushViewController(vc, animated: true)
                    } else {
                        vc.modalPresentationStyle = .overFullScreen
                        self?.present(vc, animated: true)
                    }
                }
                
                if let vc = self, let delegate = vc.delegate {
                    delegate.walletViewControllerSelectedRow(vc)
                }
            }
            
            section.append(sendRow)
        }
        
        form.append(section)
        
        // MARK: Notification
        if let service = service {
            // MARK: Wallet updated
            let walletUpdatedCallback = { [weak self] (_: Notification) in
                if let row: LabelRow = self?.form.rowBy(tag: BaseRows.address.tag) {
                    if let wallet = service.wallet {
                        row.value = wallet.address
                        row.updateCell()
                    }
                }
                
                guard let service = self?.service,
                      let wallet = service.wallet,
                      let vc = self,
                      let row: BalanceRow = vc.form.rowBy(tag: BaseRows.balance.tag) else {
                    return
                }
                
                if let currentCurrency = self?.currencyInfoService.currentCurrency {
                    self?.fiatFormatter.currencyCode = currentCurrency.rawValue
                }
                
                let symbol = service.tokenSymbol
                row.value = vc.balanceRowValueFor(
                    balance: wallet.balance,
                    symbol: symbol,
                    alert: wallet.notifications,
                    isBalanceInitialized: wallet.isBalanceInitialized
                )
                row.updateCell()
            }
            
            NotificationCenter.default.addObserver(forName: service.walletUpdatedNotification,
                                                   object: service,
                                                   queue: OperationQueue.main,
                                                   using: walletUpdatedCallback)
            
            NotificationCenter.default.addObserver(forName: Notification.Name.AdamantCurrencyInfoService.currencyRatesUpdated,
                                                   object: nil,
                                                   queue: OperationQueue.main,
                                                   using: walletUpdatedCallback)
            
            // MARK: Wallet state updated
            let stateUpdatedCallback = { [weak self] (notification: Notification) in
                guard let newState = notification.userInfo?[AdamantUserInfoKey.WalletService.walletState] as? WalletServiceState else {
                    return
                }
                
                self?.setUiToWalletServiceState(newState)
            }
            
            NotificationCenter.default.addObserver(forName: service.serviceStateChanged,
                                                   object: service,
                                                   queue: OperationQueue.main,
                                                   using: stateUpdatedCallback)
        }
        
        if let state = service?.state {
            switch state {
            case .updating:
                setUiToWalletServiceState(.notInitiated)
                
            default:
                setUiToWalletServiceState(state)
            }
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
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
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
            if let wallet = service?.wallet {
                $0.value = wallet.address
            }
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (cell, row) in
            row.deselect()
            let completion = { [weak self] in
                guard let tableView = self?.tableView, let indexPath = tableView.indexPathForSelectedRow else {
                    return
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            if let address = self?.service?.wallet?.address {
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
    
    // MARK: - Other
    
    private var currentUiState: WalletServiceState = .upToDate
    
    func setUiToWalletServiceState(_ state: WalletServiceState) {
        guard currentUiState != state else {
            return
        }
        
        switch state {
        case .updating:
            break
            
        case .upToDate:
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

// MARK: - TransferViewControllerDelegate
extension WalletViewControllerBase: TransferViewControllerDelegate {
    func transferViewController(_ viewController: TransferViewControllerBase, didFinishWithTransfer transfer: TransactionDetails?, detailsViewController: UIViewController?) {
        DispatchQueue.onMainAsync { [weak self] in
            if let split = self?.splitViewController {
                if let nav = split.viewControllers.last as? UINavigationController {
                    if let detailsViewController = detailsViewController {
                        var viewControllers = nav.viewControllers
                        viewControllers.removeLast()
                        
                        if let service = self?.service as? WalletServiceWithTransfers {
                            viewControllers.append(service.transferListViewController())
                        }
                        
                        viewControllers.append(detailsViewController)
                        nav.setViewControllers(viewControllers, animated: true)
                    } else {
                        nav.popViewController(animated: true)
                    }
                } else {
                    split.showDetailViewController(viewController, sender: nil)
                }
            } else if let nav = self?.navigationController {
                if let detailsViewController = detailsViewController {
                    var viewControllers = nav.viewControllers
                    viewControllers.removeLast()
                    viewControllers.append(detailsViewController)
                    nav.setViewControllers(viewControllers, animated: true)
                } else {
                    nav.popViewController(animated: true)
                }
            } else if self?.presentedViewController == viewController {
                self?.dismiss(animated: true, completion: nil)
                
                if let detailsViewController = detailsViewController {
                    detailsViewController.modalPresentationStyle = .overFullScreen
                    self?.present(detailsViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
