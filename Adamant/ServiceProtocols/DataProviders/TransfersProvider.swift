//
//  TransfersProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData

enum TransfersProviderError: Error {
    case notLogged
    case serverError(Error)
    case accountNotFound(address: String)
    case transactionNotFound(id: String)
    case internalError(message: String, error: Error?)
    case dependencyError(message: String)
    case networkError
    case notEnoughMoney
    case requestCancelled
}

enum TransfersProviderResult {
    case success
    case failure(TransfersProviderError)
}

enum TransfersProviderTransferResult {
    case success(transaction: TransactionDetails)
    case failure(TransfersProviderError)
}

extension TransfersProviderError: RichError {
    var message: String {
        switch self {
        case .notLogged:
            return String.adamantLocalized.sharedErrors.userNotLogged
            
        case .serverError(let error):
            return ApiServiceError.serverError(error: error.localizedDescription)
                .localizedDescription
            
        case .accountNotFound(let address):
            return AccountsProviderError.notFound(address: address).localized
            
        case .internalError(let message, _):
            return String.adamantLocalized.sharedErrors.internalError(message: message)
            
        case .transactionNotFound(let id):
            return String.localizedStringWithFormat(NSLocalizedString("TransfersProvider.Error.TransactionNotFoundFormat", comment: "TransfersProvider: Transaction not found error. %@ for transaction's ID"), id)
            
        case .dependencyError(let message):
            return String.adamantLocalized.sharedErrors.internalError(message: message)
            
        case .networkError:
            return String.adamantLocalized.sharedErrors.networkError
            
        case .notEnoughMoney:
            return String.adamantLocalized.sharedErrors.notEnoughMoney
            
        case .requestCancelled:
            return String.adamantLocalized.sharedErrors.requestCancelled
        }
    }
    
    var internalError: Error? {
        switch self {
        case .serverError(let error):
            return error
            
        default:
            return nil
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .notLogged, .accountNotFound, .transactionNotFound, .networkError, .notEnoughMoney, .requestCancelled:
            return .warning
        
        case .serverError:
            return .error
            
        case .internalError, .dependencyError:
            return .internalError
        }
    }
    
}

extension Notification.Name {
    struct AdamantTransfersProvider {
        /// userInfo contains 'newTransactions' element. See AdamantUserInfoKey.TransfersProvider
        static let newTransactions = Notification.Name("adamant.transfersProvider.newTransactions")
        
        /// userInfo contains newState element. See AdamantUserInfoKey.TransfersProvider
        static let stateChanged = Notification.Name("adamant.transfersProvider.stateChanged")
        
        static let initialSyncFinished = Notification.Name("adamant.transfersProvider.initialSyncFinished")
        
        private init() {}
    }
}

extension AdamantUserInfoKey {
    struct TransfersProvider {
        /// New provider state
        static let newState = "transfersNewState"
        
        /// Previous provider state, if avaible
        static let prevState = "transfersPrevState"
        
        // New received transactions
        static let newTransactions = "transfersNewTransactions"
        
        /// lastMessageHeight: new lastMessageHeight
        static let lastTransactionHeight = "adamant.transfersProvider.newTransactions.lastHeight"
        
        private init() {}
    }
}

extension StoreKey {
    struct transfersProvider {
        static let address = "transfersProvider.address"
        static let receivedLastHeight = "transfersProvider.receivedLastHeight"
        static let readedLastHeight = "transfersProvider.readedLastHeight"
        static let notifiedLastHeight = "transfersProvider.notifiedLastHeight"
        static let notifiedTransfersCount = "transfersProvider.notifiedCount"
    }
}

protocol TransfersProvider: DataProvider, Actor {
    // MARK: - Constants
    static var transferFee: Decimal { get }
    
    // MARK: - Properties
    var receivedLastHeight: Int64? { get }
    var readedLastHeight: Int64? { get }
    var isInitiallySynced: Bool { get }
    var hasTransactions: Bool { get }
    var offsetTransactions: Int { get set }
    
    // MARK: Controller
    func transfersController() -> NSFetchedResultsController<TransferTransaction>
    func unreadTransfersController() -> NSFetchedResultsController<TransferTransaction>
    
    func transfersController(for account: CoreDataAccount) -> NSFetchedResultsController<TransferTransaction>

    // Force update transactions
    func update() async -> TransfersProviderResult?
    
    // MARK: - Sending funds
    func transferFunds(
        toAddress recipient: String,
        amount: Decimal,
        comment: String?,
        replyToMessageId: String?
    ) async throws -> TransactionDetails
    
    // MARK: - Transactions
    func getTransfer(id: String) -> TransferTransaction?
    func refreshTransfer(id: String) async throws
    
    /// Load moore transactions
    func getTransactions(
        forAccount account: String,
        type: TransactionType,
        offset: Int,
        limit: Int,
        orderByTime: Bool
    ) async throws -> Int
    
    func updateOffsetTransactions(_ value: Int)
}
