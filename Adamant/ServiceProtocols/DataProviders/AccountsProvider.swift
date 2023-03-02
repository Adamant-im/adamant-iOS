//
//  AccountsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum AccountsProviderError: Error {
    case dummy(BaseAccount)
    case notFound(address: String)
    case invalidAddress(address: String)
    case notInitiated(address: String)
    case serverError(Error)
    case networkError(Error)
    
    var localized: String {
        switch self {
        case .dummy:
            return "Dummy"
            
        case .notFound(let address):
            return String.adamantLocalized.sharedErrors.accountNotFound(address)
            
        case .invalidAddress(let address):
            return String.localizedStringWithFormat(NSLocalizedString("AccountsProvider.Error.AddressNotValidFormat", comment: "AccountsProvider: Address not valid error, %@ for address"), address)
            
        case .notInitiated:
            return String.adamantLocalized.sharedErrors.accountNotInitiated
            
        case .serverError(let error):
            return ApiServiceError.serverError(error: error.localizedDescription)
                .localizedDescription
            
        case .networkError:
            return String.adamantLocalized.sharedErrors.networkError
        }
    }
}

enum AccountsProviderDummyAccountError: Error {
    case foundRealAccount(CoreDataAccount)
    case invalidAddress(address: String)
    case internalError(Error)
}

protocol AccountsProvider {
    
    /// Search for fetched account, if not found, asks server for account.
    ///
    /// - Returns: Account, if found, created in main viewContext
    func getAccount(byAddress address: String) async throws -> CoreDataAccount
    
    /// Search for fetched account, if not found try to create or asks server for account.
    ///
    /// - Returns: Account, if found, created in main viewContext
    func getAccount(byAddress address: String, publicKey: String) async throws -> CoreDataAccount
    
    /* That one bugged. Will be fixed later. Maybe. */
    /// Search for fetched account, if not found, asks server for account.
    ///
    /// - Returns: Account, if found, created in main viewContext
//    func getAccount(byPublicKey publicKey: String, completion: @escaping (AccountsProviderResult) -> Void)
    
    /// Check locally if has account with specified address
    func hasAccount(address: String) async -> Bool
    
    /// Request Dummy account, if account wasn't found or initiated
    func getDummyAccount(for address: String) async throws -> DummyAccount
}

// MARK: - Known contacts
struct SystemMessage {
    let message: AdamantMessage
    let silentNotification: Bool
}

enum AdamantContacts {
    case adamantBountyWallet
    case adamantNewBountyWallet
    case adamantIco
    case iosSupport
    case adamantExchange
    case betOnBitcoin
    case donate
    case adamantWelcomeWallet
    
    static let systemAddresses: [String] = {
        return [AdamantContacts.adamantExchange.name, AdamantContacts.betOnBitcoin.name, AdamantContacts.adamantIco.name, AdamantContacts.adamantBountyWallet.name, AdamantContacts.adamantNewBountyWallet.name, AdamantContacts.donate.name, AdamantContacts.adamantWelcomeWallet.name]
    }()
    
    static func messagesFor(address: String) -> [String:SystemMessage]? {
        switch address {
        case AdamantContacts.adamantBountyWallet.address,
             AdamantContacts.adamantBountyWallet.name,
             AdamantContacts.adamantNewBountyWallet.address,
             AdamantContacts.adamantNewBountyWallet.name:
            return AdamantContacts.adamantBountyWallet.messages
            
        case AdamantContacts.adamantIco.address, AdamantContacts.adamantIco.name:
            return AdamantContacts.adamantIco.messages
            
        case AdamantContacts.adamantExchange.address, AdamantContacts.adamantExchange.name:
            return AdamantContacts.adamantExchange.messages
            
        case AdamantContacts.betOnBitcoin.address, AdamantContacts.betOnBitcoin.name:
            return AdamantContacts.betOnBitcoin.messages
            
        default:
            return nil
        }
    }
    
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
        }
    }
    
    var isSystem: Bool {
        switch self {
        case .adamantExchange, .betOnBitcoin:
            return false
        default:
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
        }
    }
    
    var isReadonly: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet, .adamantIco, .adamantWelcomeWallet: return true
        case .iosSupport, .adamantExchange, .betOnBitcoin, .donate: return false
        }
    }
    
    var isHidden: Bool {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet: return true
        case .adamantIco, .iosSupport, .adamantExchange, .betOnBitcoin, .donate, .adamantWelcomeWallet: return false
        }
    }
    
    var avatar: String {
        switch self {
        case .adamantExchange, .betOnBitcoin, .donate, .adamantBountyWallet, .adamantNewBountyWallet:
            return ""
        default:
            return "avatar_bots"
        }
    }
    
    var messages: [String: SystemMessage] {
        switch self {
        case .adamantBountyWallet, .adamantNewBountyWallet:
            return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported.")),
                                                           silentNotification: true)]
        case .adamantWelcomeWallet:
            return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported.")),
                                                           silentNotification: true)]
        case .adamantIco:
            return [
                "chats.preico_message": SystemMessage(message: AdamantMessage.text(NSLocalizedString("Chats.PreIcoMessage", comment: "Known contacts: Adamant pre ICO message")),
                                                      silentNotification: true),
                "chats.ico_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.IcoMessage", comment: "Known contacts: Adamant ICO message. Markdown supported.")),
                                                   silentNotification: true)
            ]
            
        case .iosSupport:
            return [:]
            
        case .donate:
            return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.Donate.WelcomeMessage", comment: "Known contacts: Adamant donate welcome message. Markdown supported.")),
                                                           silentNotification: true)]
            
        case .adamantExchange:
            return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.Exchange.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported.")),
                                                           silentNotification: true)]
            
        case .betOnBitcoin:
            return ["chats.welcome_message": SystemMessage(message: AdamantMessage.markdownText(NSLocalizedString("Chats.BetOnBitcoin.WelcomeMessage", comment: "Known contacts: Adamant welcome message. Markdown supported.")),
                                                           silentNotification: true)]
        }
    }
}
