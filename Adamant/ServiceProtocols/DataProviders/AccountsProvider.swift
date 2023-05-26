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

extension AdamantContacts {
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
            
        case AdamantContacts.adelina.address, AdamantContacts.adelina.name:
            return AdamantContacts.adelina.messages
            
        default:
            return nil
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
            
        case .iosSupport, .pwaBountyBot:
            return [:]
            
        case .donate:
            return ["chats.welcome_message": SystemMessage(
                message: AdamantMessage.markdownText(
                    NSLocalizedString(
                        "Chats.Donate.WelcomeMessage",
                        comment: "Known contacts: Adamant donate welcome message. Markdown supported."
                    )
                ),
                silentNotification: true
            )]
            
        case .adamantExchange:
            return ["chats.welcome_message": SystemMessage(
                message: AdamantMessage.markdownText(
                    NSLocalizedString(
                        "Chats.Exchange.WelcomeMessage",
                        comment: "Known contacts: Adamant welcome message. Markdown supported."
                    )
                ),
                silentNotification: true
            )]
            
        case .betOnBitcoin:
            return ["chats.welcome_message": SystemMessage(
                message: AdamantMessage.markdownText(
                    NSLocalizedString(
                        "Chats.BetOnBitcoin.WelcomeMessage",
                        comment: "Known contacts: Adamant welcome message. Markdown supported."
                    )
                ),
                silentNotification: true
            )]
        case .adelina:
            return ["chats.welcome_message": SystemMessage(
                message: AdamantMessage.markdownText(
                    NSLocalizedString(
                        "Chats.Adelina.WelcomeMessage",
                        comment: "Known contacts: Adamant welcome message. Markdown supported."
                    )
                ),
                silentNotification: true
            )]
        }
    }
}
