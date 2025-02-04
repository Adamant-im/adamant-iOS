//
//  AdamantContacts.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 22.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public enum AdamantContacts: CaseIterable {
    case pwaBountyBot
    case adamantBountyWallet
    case adamantNewBountyWallet
    case adamantIco
    case adamantSupport
    case adamantExchange
    case betOnBitcoin
    case donate
    case adamantWelcomeWallet
    case adelina
    
    public static var systemAddresses: [String] {
        Self.allCases.map { $0.name }
    }
    
    public var name: String {
        switch self {
        case .adamantWelcomeWallet:
            return .localized("Accounts.AdamantTokens", comment: "System accounts: ADAMANT Tokens")
        case .adamantBountyWallet, .adamantNewBountyWallet:
            return .localized("Accounts.AdamantBounty", comment: "System accounts: ADAMANT Bounty")
        case .adamantIco:
            return "Adamant ICO"
        case .adamantSupport:
            return .localized("Accounts.Support", comment: "System accounts: ADAMANT Support")
        case .adamantExchange:
            return .localized("Accounts.AdamantExchange", comment: "System accounts: ADAMANT Exchange")
        case .betOnBitcoin:
            return .localized("Accounts.BetOnBitcoin", comment: "System accounts: Bet on Bitcoin Price")
        case .donate:
            return .localized("Accounts.DonateADMFoundation", comment: "System accounts: Donates ADAMANT Foundation")
        case .adelina:
            return .localized("Accounts.Adelina", comment: "System accounts: Adelina")
        case .pwaBountyBot:
            return .localized("Accounts.AdamantBountyBot", comment: "System accounts: PWA ADM Bounty bot")
        }
    }
    
    public var isSystem: Bool {
        switch self {
        case .adamantExchange, .betOnBitcoin, .adelina, .donate:
            return false
        case .adamantWelcomeWallet, .adamantSupport, .adamantIco, .adamantBountyWallet, .adamantNewBountyWallet, .pwaBountyBot:
            return true
        }
    }
    
    public var address: String {
        switch self {
        case .adamantBountyWallet: return AdamantResources.contacts.adamantBountyWallet
        case .adamantNewBountyWallet: return AdamantResources.contacts.adamantNewBountyWallet
        case .adamantIco: return AdamantResources.contacts.adamantIco
        case .adamantSupport: return AdamantResources.contacts.adamantSupport
        case .adamantExchange: return AdamantResources.contacts.adamantExchange
        case .betOnBitcoin: return AdamantResources.contacts.betOnBitcoin
        case .donate: return AdamantResources.contacts.donateWallet
        case .adamantWelcomeWallet: return AdamantResources.contacts.adamantWelcomeWallet
        case .adelina: return AdamantResources.contacts.adelinaWallet
        case .pwaBountyBot: return AdamantResources.contacts.pwaBountyBot
        }
    }
    
    public var publicKey: String? {
        switch self {
        case .adamantExchange: return AdamantResources.contacts.adamantExchangePK
        case .betOnBitcoin: return AdamantResources.contacts.betOnBitcoinPK
        case .adamantBountyWallet: return AdamantResources.contacts.adamantBountyWalletPK
        case .adamantNewBountyWallet: return AdamantResources.contacts.adamantNewBountyWalletPK
        case .adamantSupport: return AdamantResources.contacts.adamantSupportPK
        case .adamantIco: return AdamantResources.contacts.adamantIcoPK
        case .donate: return AdamantResources.contacts.donateWalletPK
        case .adamantWelcomeWallet: return AdamantResources.contacts.adamantBountyWalletPK
        case .adelina: return AdamantResources.contacts.adelinaWalletPK
        case .pwaBountyBot: return AdamantResources.contacts.pwaBountyBotPK
        }
    }
    
    public var isReadonly: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet, .adamantIco, .adamantWelcomeWallet: return true
        case .adamantSupport, .adamantExchange, .betOnBitcoin, .donate, .adelina, .pwaBountyBot: return false
        }
    }
    
    public var isHidden: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet, .pwaBountyBot: return true
        case .adamantIco, .adamantSupport, .adamantExchange, .betOnBitcoin, .donate, .adamantWelcomeWallet, .adelina: return false
        }
    }
    
    public var avatar: String {
        switch self {
        case .adamantExchange, .betOnBitcoin, .donate, .adamantBountyWallet, .adamantNewBountyWallet, .adelina, .pwaBountyBot:
            return ""
        case .adamantIco, .adamantSupport, .adamantWelcomeWallet:
            return "avatar_bots"
        }
    }
    
    public var nodeNameKey: String? {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet:
            return "chats.virtual.bounty_wallet_title"
        case .adamantExchange:
            return "chats.virtual.exchange_bot_title"
        case .betOnBitcoin:
            return "chats.virtual.bitcoin_bet_title"
        case .donate:
            return "chats.virtual.donate_bot_title"
        case .adelina:
            return "chats.virtual.adelina_title"
        case .pwaBountyBot:
            return "chats.virtual.bounty_bot_title"
        case .adamantIco, .adamantWelcomeWallet, .adamantSupport:
            return nil
        }
    }
}

public extension AdamantContacts {
    init?(nodeNameKey: String) {
        guard
            let contact = Self.allCases
                .first(where: { nodeNameKey == $0.nodeNameKey })
        else { return nil }
        self = contact
    }
    
    init?(address: String) {
        guard
            let contact = Self.allCases
                .first(where: { address == $0.address })
        else { return nil }
        self = contact
    }
}
