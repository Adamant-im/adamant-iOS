//
//  BuyAndSellViewController.swift
//  Adamant
//
//  Created by Anokhov Pavel on 22/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Eureka
import SafariServices

class BuyAndSellViewController: FormViewController {
    // MARK: Rows
    enum Rows {
        case adamant
        case bitz
        case idcm
        
        var tag: String {
            switch self {
            case .adamant: return "adm"
            case .bitz: return "bitz"
            case .idcm: return "idcm"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .adamant: return #imageLiteral(resourceName: "row_logo")
            case .bitz: return #imageLiteral(resourceName: "bitz_row_logo.png")
            case .idcm: return #imageLiteral(resourceName: "idcm_row_logo.png")
            }
        }
        
        var localized: String {
            switch self {
            case .adamant: return String.adamantLocalized.wallets.buyAdmTokens
            case .bitz: return "Bit-Z"
            case .idcm: return "IDCM"
            }
        }
        
        var url: String {
            switch self {
            case .adamant: return "https://adamant.im/buy-tokens/"
            case .bitz: return "https://www.bit-z.com/exchange/adm_usdt"
            case .idcm: return "https://www.idcm.io/trading/ADM_BTC"
            }
        }
    }
    
    // MARK: - Props & Dependencies
    
    var accountService: AccountService!
    var dialogService: DialogService!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = AdmWalletViewController.Rows.buyTokens.localized
        
        let section = Section()
        
        // MARK: Adamant
        let admUrl: String
        
        if let account = accountService.account {
            admUrl = String.adamantLocalized.wallets.buyTokensUrl(for: account.address)
        } else {
            admUrl = Rows.adamant.url
        }
        
        let admRow = buildUrlRow(title: Rows.adamant.localized, value: nil, tag: Rows.adamant.tag, urlRaw: admUrl, image: Rows.adamant.image)
        
        section.append(admRow)
        
        // MARK: Bit-Z
        let bitzRow = buildUrlRow(for: .bitz)
        section.append(bitzRow)
        
        // MARK: IDCM
        let idcmRow = buildUrlRow(for: .idcm)
        section.append(idcmRow)
        
        form.append(section)
    }
    
    // MARK: - Tools
    
    private func buildUrlRow(for row: Rows) -> LabelRow {
        return buildUrlRow(title: row.localized, value: nil, tag: row.tag, urlRaw: row.url, image: row.image)
    }
    
    private func buildUrlRow(title: String, value: String?, tag: String, urlRaw: String, image: UIImage?) -> LabelRow {
        let row = LabelRow() {
            $0.tag = tag
            $0.title = title
            $0.value = value
            $0.cell.imageView?.image = image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, _) in
            guard let url = URL(string: urlRaw) else {
                self?.dialogService.showError(withMessage: "Failed to create URL with string: \(urlRaw)", error: nil)
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            self?.present(safari, animated: true, completion: nil)
        }
        
        return row
    }
}
