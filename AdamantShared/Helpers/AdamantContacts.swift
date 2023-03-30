//
//  AdamantContacts.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 22.03.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

enum AdamantContacts {
    case adamantBountyWallet
    case adamantNewBountyWallet
    case adamantIco
    case iosSupport
    case adamantExchange
    case betOnBitcoin
    case donate
    case adamantWelcomeWallet
    case adelina
    
    static let systemAddresses = [
        AdamantContacts.adelina.name,
        AdamantContacts.adamantExchange.name,
        AdamantContacts.betOnBitcoin.name,
        AdamantContacts.adamantIco.name,
        AdamantContacts.adamantBountyWallet.name,
        AdamantContacts.adamantNewBountyWallet.name,
        AdamantContacts.donate.name,
        AdamantContacts.adamantWelcomeWallet.name
    ]
    
    var name: String {
        switch self {
        case .adamantWelcomeWallet:
            return NSLocalizedString("Accounts.AdamantTokens", comment: "System accounts: ADAMANT Tokens")
        case .adamantBountyWallet, .adamantNewBountyWallet:
            return NSLocalizedString("Accounts.AdamantBounty", comment: "System accounts: ADAMANT Bounty")
        case .adamantIco:
            return "Adamant ICO"
        case .iosSupport:
            return NSLocalizedString("Accounts.iOSSupport", comment: "System accounts: ADAMANT iOS Support")
        case .adamantExchange:
            return NSLocalizedString("Accounts.AdamantExchange", comment: "System accounts: ADAMANT Exchange")
        case .betOnBitcoin:
            return NSLocalizedString("Accounts.BetOnBitcoin", comment: "System accounts: Bet on Bitcoin Price")
        case .donate:
            return NSLocalizedString("Accounts.DonateADMFoundation", comment: "System accounts: Donates ADAMANT Foundation")
        case .adelina:
            return NSLocalizedString("Accounts.Adelina", comment: "System accounts: Adelina")
        }
    }
    
    var isSystem: Bool {
        switch self {
        case .adamantExchange, .betOnBitcoin, .adelina:
            return false
        case .adamantWelcomeWallet, .iosSupport, .adamantIco, .adamantBountyWallet, .adamantNewBountyWallet, .donate:
            return true
        }
    }
    
    var address: String {
        switch self {
        case .adamantBountyWallet: return AdamantResources.contacts.adamantBountyWallet
        case .adamantNewBountyWallet: return AdamantResources.contacts.adamantNewBountyWallet
        case .adamantIco: return AdamantResources.contacts.adamantIco
        case .iosSupport: return AdamantResources.contacts.iosSupport
        case .adamantExchange: return AdamantResources.contacts.adamantExchange
        case .betOnBitcoin: return AdamantResources.contacts.betOnBitcoin
        case .donate: return AdamantResources.contacts.donateWallet
        case .adamantWelcomeWallet: return AdamantResources.contacts.adamantWelcomeWallet
        case .adelina: return AdamantResources.contacts.adelinaWallet
        }
    }
    
    var publicKey: String? {
        switch self {
        case .adamantExchange: return AdamantResources.contacts.adamantExchangePK
        case .betOnBitcoin: return AdamantResources.contacts.betOnBitcoinPK
        case .adamantBountyWallet: return AdamantResources.contacts.adamantBountyWalletPK
        case .adamantNewBountyWallet: return AdamantResources.contacts.adamantNewBountyWalletPK
        case .iosSupport: return AdamantResources.contacts.iosSupportPK
        case .adamantIco: return AdamantResources.contacts.adamantIcoPK
        case .donate: return AdamantResources.contacts.donateWalletPK
        case .adamantWelcomeWallet: return AdamantResources.contacts.adamantBountyWalletPK
        case .adelina: return AdamantResources.contacts.adelinaWalletPK
        }
    }
    
    var isReadonly: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet, .adamantIco, .adamantWelcomeWallet: return true
        case .iosSupport, .adamantExchange, .betOnBitcoin, .donate, .adelina: return false
        }
    }
    
    var isHidden: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet: return true
        case .adamantIco, .iosSupport, .adamantExchange, .betOnBitcoin, .donate, .adamantWelcomeWallet, .adelina: return false
        }
    }
    
    var avatar: String {
        switch self {
        case .adamantExchange, .betOnBitcoin, .donate, .adamantBountyWallet, .adamantNewBountyWallet, .adelina:
            return ""
        case .adamantIco, .iosSupport, .adamantWelcomeWallet:
            return "avatar_bots"
        }
    }
}
