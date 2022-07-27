//
//  AdmWalletViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import SafariServices
import Eureka

extension String.adamantLocalized.wallets {
    static let adamant = NSLocalizedString("AccountTab.Wallets.adamant_wallet", comment: "Account tab: Adamant wallet")
    
    static let sendAdm = NSLocalizedString("AccountTab.Row.SendAdm", comment: "Account tab: 'Send ADM tokens' button")
    
    static let buyAdmTokens = NSLocalizedString("AccountTab.Row.AnonymouslyBuyADM", comment: "Account tab: Anonymously buy ADM tokens")

    static let exchangeInChatAdmTokens = NSLocalizedString("AccountTab.Row.ExchangeADMInChat", comment: "Account tab: Exchange ADM in chat")
    // URLs
    static func getFreeTokensUrl(for address: String) -> String {
        return String.localizedStringWithFormat(NSLocalizedString("AccountTab.FreeTokens.UrlFormat", comment: "Account tab: A full 'Get free tokens' link, with %@ as address"), address)
    }
    
    static func buyTokensUrl(for address: String) -> String {
        return String.localizedStringWithFormat(NSLocalizedString("AccountTab.BuyTokens.UrlFormat", comment: "Account tab: A full 'Buy tokens' link, with %@ as address"), address)
    }
    
    static let getFreeTokensUrlFormat = ""
    static let buyTokensUrlFormat = ""
}

class AdmWalletViewController: WalletViewControllerBase {
    // MARK: - Rows & Sections
    enum Rows {
        case buyTokens, freeTokens
        
        var tag: String {
            switch self {
            case .buyTokens: return "bTkns"
            case .freeTokens: return "frrTkns"
            }
        }
        
        var localized: String {
            switch self {
            case .buyTokens: return NSLocalizedString("AccountTab.Row.BuyTokens", comment: "Account tab: 'Buy tokens' button")
            case .freeTokens: return NSLocalizedString("AccountTab.Row.FreeTokens", comment: "Account tab: 'Get free tokens' button")
            }
        }
        
        var image: UIImage? {
            switch self {
            case .buyTokens: return #imageLiteral(resourceName: "row_buy-coins")
            case .freeTokens: return #imageLiteral(resourceName: "row_free-tokens")
            }
        }
    }
    
    // MARK: - Props & Deps
    
    var router: Router!
    
    var hideFreeTokensRow = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        walletTitleLabel.text = String.adamantLocalized.wallets.adamant
        
        if let balance = service?.wallet?.balance {
            hideFreeTokensRow = balance > 0
        } else {
            hideFreeTokensRow = true
        }
        
        guard let section = form.allSections.last else {
            return
        }
        
        // MARK: Rows
        
        let buyTokensRow = LabelRow() {
            $0.tag = Rows.buyTokens.tag
            $0.title = Rows.buyTokens.localized
            $0.cell.imageView?.image = Rows.buyTokens.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
            $0.cell.backgroundColor = UIColor.adamant.cellColor
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
            if self.hideFreeTokensRow {
                cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            }
        }.onCellSelection { [weak self] (_, row) in
            guard let vc = self?.router.get(scene: AdamantScene.Wallets.Adamant.buyAndSell) else {
                fatalError("Failed to get BuyAndSell scele")
            }

            row.deselect()

            if let split = self?.splitViewController {
                let details = UINavigationController(rootViewController:vc)
                split.showDetailViewController(details, sender: self)
            } else {
                self?.navigationController?.pushViewController(vc, animated: true )
            }
        }
        
        let freeTokensRow = LabelRow() {
            $0.tag = Rows.freeTokens.tag
            $0.title = Rows.freeTokens.localized
            $0.cell.imageView?.image = Rows.freeTokens.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
            $0.hidden = Condition.function([], { [weak self] _ -> Bool in
                return self?.hideFreeTokensRow ?? true
            })
            $0.cell.backgroundColor = UIColor.adamant.cellColor
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }.onCellSelection { [weak self] (_, row) in
            row.deselect()
            if let address = self?.service?.wallet?.address {
                let urlRaw = String.adamantLocalized.wallets.getFreeTokensUrl(for: address)
                guard let url = URL(string: urlRaw) else {
                    self?.dialogService.showError(withMessage: "Failed to create URL with string: \(urlRaw)", error: nil)
                    return
                }
                
                let safari = SFSafariViewController(url: url)
                safari.preferredControlTintColor = UIColor.adamant.primary
                safari.modalPresentationStyle = .overFullScreen
                self?.present(safari, animated: true, completion: nil)
            }
        }
        
        section.append(buyTokensRow)
        section.append(freeTokensRow)
        
         // Notifications
        if let service = service {
            NotificationCenter.default.addObserver(forName: service.walletUpdatedNotification,
                                                   object: service,
                                                   queue: OperationQueue.main,
                                                   using: { [weak self] _ in self?.updateRows() })
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.updateRows()
            self?.tableView.reloadData()
        }
        
        updateTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateTheme()
    }
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.wallets.sendAdm
    }
    
    override func encodeForQr(address: String) -> String? {
        return AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
    }
    
    override func adressRow() -> LabelRow {
        let addressRow = LabelRow() {
            $0.tag = BaseRows.address.tag
            $0.title = BaseRows.address.localized
            $0.cell.selectionStyle = .gray
            $0.cell.backgroundColor = UIColor.adamant.cellColor
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
                let encodedAddress = AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
                self?.dialogService.presentShareAlertFor(stringForPasteboard: address,
                                                   stringForShare: encodedAddress,
                                                   stringForQR: encodedAddress,
                                                   types: [.copyToPasteboard,
                                                           .share,
                                                           .generateQr(encodedContent: encodedAddress, sharingTip: address, withLogo: true)
                                                          ],
                                                   excludedActivityTypes: ShareContentType.address.excludedActivityTypes,
                                                   animated: true,
                                                   from: cell,
                                                   completion: completion)
            }
        }
        return addressRow
    }
    
    func updateRows() {
        guard let admService = service as? AdmWalletService, let wallet = admService.wallet as? AdmWallet else {
            return
        }
        
        hideFreeTokensRow = wallet.balance > 0
        
        if let row: LabelRow = form.rowBy(tag: Rows.freeTokens.tag) {
            row.evaluateHidden()
        }

        NotificationCenter.default.post(name: Notification.Name.WalletViewController.heightUpdated, object: self)
    }
    
    override func includeLogoInQR() -> Bool {
        return true
    }
}
