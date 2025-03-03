//
//  TableView.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 09.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import UIKit

extension AccountViewController {
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
        case security, nodes, coinsNodes, theme, currency, language, about, visibleWallets, contribute, storage // Application
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
            case .coinsNodes: return "coinsNodes"
            case .language: return "language"
            case .storage: return "storage"
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
            case .coinsNodes: return .adamant.coinsNodesList.title
            case .language: return .localized("AccountTab.Row.Language", comment: "Account tab: 'Language' row")
            case .storage: return .localized("StorageUsage.Title", comment: "Storage Usage: Title")
            }
        }
        
        var image: UIImage? {
            var image: UIImage?
            switch self {
            case .security: image = .asset(named: "row_security")
            case .about: image = .asset(named: "row_about")
            case .theme: image = .asset(named: "row_themes.png")
            case .currency: image = .asset(named: "row_currency")
            case .nodes: image = .asset(named: "row_nodes")
            case .coinsNodes: image = .init(systemName: "server.rack")
            case .balance: image = .asset(named: "row_balance")
            case .voteForDelegates: image = .asset(named: "row_vote-delegates")
            case .logout: image = .asset(named: "row_logout")
            case .sendTokens: image = nil
            case .generateQr: image = .asset(named: "row_QR.png")
            case .generatePk: image = .asset(named: "privateKey_row")
            case .stayIn: image = .asset(named: "row_security")
            case .biometry: image = nil // Determined by localAuth service
            case .notifications: image = .asset(named: "row_Notifications.png")
            case .visibleWallets: image = .asset(named: "row_balance")
            case .contribute: image = .asset(named: "row_contribute")
            case .language: image = .asset(named: "row_language")
            case .storage: image = .asset(named: "row_storage")
            }
            
            return image?
                .imageResized(to: .init(squareSize: 24))
                .withTintColor(.adamant.tableRowIcons)
        }
    }
    
}
