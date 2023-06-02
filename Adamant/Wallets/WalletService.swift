//
//  Wallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Swinject

enum WalletServiceState: Equatable {
    case notInitiated, updating, upToDate, initiationFailed(reason: String)
}

enum WalletServiceSimpleResult {
    case success
    case failure(error: WalletServiceError)
}

enum WalletServiceResult<T> {
    case success(result: T)
    case failure(error: WalletServiceError)
}

// MARK: - Errors

enum WalletServiceError: Error {
    case notLogged
    case notEnoughMoney
    case networkError
    case accountNotFound
    case walletNotInitiated
    case invalidAmount(Decimal)
    case remoteServiceError(message: String)
    case apiError(ApiServiceError)
    case internalError(message: String, error: Error?)
    case transactionNotFound(reason: String)
    case requestCancelled
    case dustAmountError
}

extension WalletServiceError: RichError {
    var message: String {
        switch self {
        case .notLogged:
            return String.adamantLocalized.sharedErrors.userNotLogged
            
        case .notEnoughMoney:
            return String.adamantLocalized.sharedErrors.notEnoughMoney
            
        case .networkError:
            return String.adamantLocalized.sharedErrors.networkError
            
        case .accountNotFound:
            return String.adamantLocalized.transfer.accountNotFound
            
        case .walletNotInitiated:
            return NSLocalizedString("WalletServices.SharedErrors.WalletNotInitiated", comment: "Wallet Services: Shared error, user has not yet initiated a specific wallet.")
            
        case .remoteServiceError(let message):
            return String.adamantLocalized.sharedErrors.remoteServerError(message: message)
            
        case .apiError(let error):
            return error.localizedDescription
            
        case .internalError(let message, _):
            return String.adamantLocalized.sharedErrors.internalError(message: message)
            
        case .invalidAmount(let amount):
            return String.localizedStringWithFormat(NSLocalizedString("WalletServices.SharedErrors.InvalidAmountFormat", comment: "Wallet Services: Shared error, invalid amount format. %@ for amount"), AdamantBalanceFormat.full.format(amount))
            
        case .transactionNotFound:
            return NSLocalizedString("WalletServices.SharedErrors.TransactionNotFound", comment: "Wallet Services: Shared error, transaction not found")
            
        case .requestCancelled:
            return String.adamantLocalized.sharedErrors.requestCancelled
        case .dustAmountError:
            return String.adamantLocalized.sharedErrors.dustError
        }
    }
    
    var internalError: Error? {
        switch self {
        case .internalError(_, let error): return error
        default: return nil
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .notLogged, .notEnoughMoney, .networkError, .accountNotFound, .invalidAmount, .walletNotInitiated, .transactionNotFound, .requestCancelled:
            return .warning
        
        case .dustAmountError, .remoteServiceError:
            return .error
            
        case .internalError:
            return .internalError
            
        case .apiError(let error):
            return error.level
        }
    }
}

extension ApiServiceError {
    func asWalletServiceError() -> WalletServiceError {
        switch self {
        case .accountNotFound:
            return .accountNotFound
            
        case .networkError:
            return .networkError
            
        case .notLogged:
            return .notLogged
            
        case .requestCancelled:
            return .requestCancelled
            
        case .serverError, .internalError, .commonError:
            return .apiError(self)
        }
    }
}

extension ChatsProviderError {
    func asWalletServiceError() -> WalletServiceError {
        switch self {
        case .notLogged:
            return .notLogged
            
        case .messageNotValid:
            return .notLogged
            
        case .notEnoughMoneyToSend:
            return .notEnoughMoney
            
        case .networkError:
            return .networkError
            
        case .serverError(let e as ApiServiceError):
            return .apiError(e)
            
        case .serverError(let e):
            return .internalError(message: self.message, error: e)
            
        case .accountNotFound:
            return .accountNotFound
            
        case .dependencyError(let message):
            return .internalError(message: message, error: nil)
            
        case .transactionNotFound(let id):
            return .transactionNotFound(reason: "\(id)")
            
        case .internalError(let error):
            return .internalError(message: self.message, error: error)
            
        case .accountNotInitiated:
            return .walletNotInitiated
            
        case .requestCancelled:
            return .requestCancelled
            
        case .invalidTransactionStatus:
            return .internalError(message: "Invalid Transaction Status", error: nil)
        }
    }
}

// MARK: - Notifications
extension AdamantUserInfoKey {
    struct WalletService {
        static let wallet = "Adamant.WalletService.wallet"
        static let walletState = "Adamant.WalletService.walletState"
        
        private init() {}
    }
}

// MARK: - UI
extension Notification.Name {
    struct WalletViewController {
        static let heightUpdated = Notification.Name("adamant.walletViewController")
        
        private init() {}
    }
}

protocol WalletViewController {
    var viewController: UIViewController { get }
    var height: CGFloat { get }
    var service: WalletService? { get }
}

// MARK: - Wallet Service
protocol WalletService: AnyObject {
	// MARK: Currency
	static var currencySymbol: String { get }
	static var currencyLogo: UIImage { get }
    static var qqPrefix: String { get }
    
    var tokenSymbol: String { get }
    var tokenName: String { get }
    var tokenLogo: UIImage { get }
    var tokenUnicID: String { get }
    var tokenNetworkSymbol: String { get }
    var consistencyMaxTime: Double { get }
    var tokenContract: String { get }
    var minBalance: Decimal { get }
    var minAmount: Decimal { get }
    var defaultVisibility: Bool { get }
    var defaultOrdinalLevel: Int? { get }
    var richMessageType: String { get }
    
	// MARK: Notifications
	
	/// Wallet updated.
	/// UserInfo contains new wallet at AdamantUserInfoKey.WalletService.wallet
	var walletUpdatedNotification: Notification.Name { get }
	
	/// Enabled state changed
	var serviceEnabledChanged: Notification.Name { get }
	
    /// State changed
    var serviceStateChanged: Notification.Name { get }
    
    // MARK: State
    var wallet: WalletAccount? { get }
    var state: WalletServiceState { get }
    var enabled: Bool { get }
    
    // MARK: Logic
    func update()
    
    // MARK: Account UI
    var walletViewController: WalletViewController { get }
    
    // MARK: Tools
    func validate(address: String) -> AddressValidationResult
    func getWalletAddress(byAdamantAddress address: String) async throws -> String
    func getBalance(address: String) async throws -> Decimal
}

protocol SwinjectDependentService: WalletService {
    func injectDependencies(from container: Container)
}

protocol InitiatedWithPassphraseService: WalletService {
    func initWallet(withPassphrase: String) async throws -> WalletAccount
    func setInitiationFailed(reason: String)
}

protocol WalletServiceWithTransfers: WalletService {
    func transferListViewController() -> UIViewController
}

// MARK: Send

protocol WalletServiceWithSend: WalletService {
    var transactionFeeUpdated: Notification.Name { get }
    
    var qqPrefix: String { get }
    var richMessageType: String { get }
    var blockchainSymbol: String { get }
    var isDynamicFee : Bool { get }
    var diplayTransactionFee : Decimal { get }
    var transactionFee : Decimal { get }
    var isWarningGasPrice : Bool { get }
    var isTransactionFeeValid : Bool { get }
    var commentsEnabledForRichMessages: Bool { get }
    var isSupportIncreaseFee: Bool { get }
    var isIncreaseFeeEnabled: Bool { get }
    var defaultIncreaseFee: Decimal { get }
    func transferViewController() -> UIViewController
}

extension WalletServiceWithSend {
    var isTransactionFeeValid: Bool {
        return true
    }
    var diplayTransactionFee: Decimal {
        return transactionFee
    }
    var commentsEnabledForRichMessages: Bool {
        return true
    }
    var blockchainSymbol: String {
        return tokenSymbol
    }
    var isDynamicFee: Bool {
        return false
    }
    var isSupportIncreaseFee: Bool {
        return false
    }
    var isIncreaseFeeEnabled: Bool {
        return false
    }
    var defaultIncreaseFee: Decimal {
        return 1.5
    }
}

protocol WalletServiceSimpleSend: WalletServiceWithSend {
    func sendMoney(
        recipient: String,
        amount: Decimal,
        comments: String,
        replyToMessageId: String?
    ) async throws -> TransactionDetails
}

protocol WalletServiceTwoStepSend: WalletServiceWithSend {
    associatedtype T: RawTransaction
    
    func createTransaction(recipient: String, amount: Decimal) async throws -> T
    func sendTransaction(_ transaction: T) async throws
}

protocol RawTransaction {
    var txHash: String? { get }
}
