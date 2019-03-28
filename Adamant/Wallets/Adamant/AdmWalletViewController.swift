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
        
        guard let section = form.allSections.last, let address = service?.wallet?.address else {
            return
        }
        
        // MARK: Rows
        
        let buyTokensRow = LabelRow() {
            $0.tag = Rows.buyTokens.tag
            $0.title = Rows.buyTokens.localized
            $0.cell.imageView?.image = Rows.buyTokens.image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
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
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            let urlRaw = String.adamantLocalized.wallets.getFreeTokensUrl(for: address)
            guard let url = URL(string: urlRaw) else {
                self?.dialogService.showError(withMessage: "Failed to create URL with string: \(urlRaw)", error: nil)
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            self?.present(safari, animated: true, completion: nil)
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
	}
    
    override func sendRowLocalizedLabel() -> String {
        return String.adamantLocalized.wallets.sendAdm
    }
    
    override func encodeForQr(address: String) -> String? {
        return AdamantUriTools.encode(request: AdamantUri.address(address: address, params: nil))
    }
    
    func updateRows() {
        guard let admService = service as? AdmWalletService, let wallet = admService.wallet as? AdmWallet else {
            return
        }
        
        hideFreeTokensRow = wallet.balance > 0
        
        if let row: LabelRow = form.rowBy(tag: Rows.freeTokens.tag) {
            row.evaluateHidden()
        }
    }
    
    override func includeLogoInQR() -> Bool {
        return true
    }
}
