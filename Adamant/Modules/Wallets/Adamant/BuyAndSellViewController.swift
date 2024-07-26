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
import CommonKit

final class BuyAndSellViewController: FormViewController {
    // MARK: Rows
    enum Rows {
        case adamantMessage
        case adamantSite
        case coinMarketCap
        case coinGecko
       
        var tag: String {
            switch self {
            case .adamantMessage: return "admChat"
            case .adamantSite: return "admSite"
            case .coinMarketCap: return "coinMarketCap"
            case .coinGecko: return "coinGecko"
            }
        }
        
        var image: UIImage? {
            switch self {
            case .adamantMessage: return .asset(named: "row_logo")
            case .adamantSite: return .asset(named: "row_logo")
            case .coinMarketCap: return .asset(named: "row_logo")
            case .coinGecko: return .asset(named: "row_logo")
            }
        }
        
        var localized: String {
            switch self {
            case .adamantMessage: return String.adamant.wallets.exchangeInChatAdmTokens
            case .adamantSite: return String.adamant.wallets.buyAdmTokens
            case .coinMarketCap: return String.adamant.wallets.exchangesOnCoinMarketCap
            case .coinGecko: return String.adamant.wallets.exchangesOnCoinGecko
            }
        }
        
        var url: String {
            switch self {
            case .adamantMessage: return ""
            case .adamantSite: return "https://adamant.im/buy-tokens/"
            case .coinMarketCap: return "https://coinmarketcap.com/currencies/adamant-messenger/#Markets"
            case .coinGecko: return "https://www.coingecko.com/en/coins/adamant-messenger#markets"
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
            admUrl = String.adamant.wallets.buyTokensUrl(for: account.address)
        } else {
            admUrl = Rows.adamantSite.url
        }
        
        // MARK: Adamant Chat
        let admChatRow = buildUrlRow(title: Rows.adamantMessage.localized, value: nil, tag: Rows.adamantMessage.tag, urlRaw: admUrl, image: Rows.adamantMessage.image)
        
        section.append(admChatRow)
        
        // MARK: Adamant Site
        let admRow = buildUrlRow(title: Rows.adamantSite.localized, value: nil, tag: Rows.adamantSite.tag, urlRaw: admUrl, image: Rows.adamantSite.image)
        
        section.append(admRow)
        
        // MARK: CoinMarketCap
        let coinMarketCap = buildUrlRow(for: .coinMarketCap)
        section.append(coinMarketCap)
        
        // MARK: CoinGecko
        let coinGecko = buildUrlRow(for: .coinGecko)
        section.append(coinGecko)
        
        form.append(section)
        
        setColors()
    }
    
    // MARK: - Tools
    
    private func buildUrlRow(for row: Rows) -> LabelRow {
        return buildUrlRow(
            title: row.localized,
            value: nil,
            tag: row.tag,
            urlRaw: row.url,
            image: row.image
        )
    }
    
    private func buildUrlRow(title: String, value: String?, tag: String, urlRaw: String, image: UIImage?) -> LabelRow {
        let row = LabelRow {
            $0.tag = tag
            $0.title = title
            $0.value = value
            $0.cell.imageView?.image = image
            $0.cell.imageView?.tintColor = UIColor.adamant.tableRowIcons
            $0.cell.selectionStyle = .gray
        }.cellUpdate { (cell, _) in
            cell.accessoryType = .disclosureIndicator
        }.onCellSelection { [weak self] (_, row) in
            row.deselect()
            if tag == Rows.adamantMessage.tag {
                self?.openExchangeChat()
                return
            }
            guard let url = URL(string: urlRaw) else {
                self?.dialogService.showError(withMessage: "Failed to create URL with string: \(urlRaw)", supportEmail: true, error: nil)
                return
            }
            
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = UIColor.adamant.primary
            safari.modalPresentationStyle = .overFullScreen
            self?.present(safari, animated: true, completion: nil)
        }
        
        return row
    }
    
    private func openExchangeChat() {
        var chatList: UINavigationController?
        var chatDetail: ChatListViewController?
        
        guard let tabbar = self.tabBarController else { return }
        
        if let split = tabbar.viewControllers?.first as? UISplitViewController,
           let navigation = split.viewControllers.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatList = navigation
            chatDetail = vc
        }
        
        if let navigation = tabbar.viewControllers?.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatList = navigation
            chatDetail = vc
        }

        let chatroom = chatDetail?.chatsController?.fetchedObjects?.first(where: { room in
            return room.partner?.address == AdamantContacts.adamantExchange.address
        })
        
        guard let chatroom = chatroom,
              let chatDetail = chatDetail
        else {
            return
        }
        
        chatList?.popToRootViewController(animated: false)
        chatList?.dismiss(animated: false, completion: nil)
        tabbar.selectedIndex = 0
        
        let vc = chatDetail.chatViewController(for: chatroom)
        
        if let split = chatDetail.splitViewController {
            let chat = UINavigationController(rootViewController: vc)
            split.showDetailViewController(chat, sender: self)
        } else if let nav = chatDetail.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            vc.modalPresentationStyle = .overFullScreen
            chatDetail.present(vc, animated: true)
        }
    }
    
    // MARK: - Other
    
    private func setColors() {
        view.backgroundColor = UIColor.adamant.secondBackgroundColor
        tableView.backgroundColor = .clear
    }
}
