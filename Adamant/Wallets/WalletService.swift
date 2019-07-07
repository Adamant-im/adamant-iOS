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
			return error.localized
			
		case .internalError(let message, _):
			return String.adamantLocalized.sharedErrors.internalError(message: message)
			
		case .invalidAmount(let amount):
            return String.localizedStringWithFormat(NSLocalizedString("WalletServices.SharedErrors.InvalidAmountFormat", comment: "Wallet Services: Shared error, invalid amount format. %@ for amount"), AdamantBalanceFormat.full.format(amount))
            
        case .transactionNotFound:
            return NSLocalizedString("WalletServices.SharedErrors.TransactionNotFound", comment: "Wallet Services: Shared error, transaction not found")
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
        case .notLogged, .notEnoughMoney, .networkError, .accountNotFound, .invalidAmount, .walletNotInitiated, .transactionNotFound:
			return .warning
			
		case .remoteServiceError, .internalError:
			return .error
			
		case .apiError(let error):
			switch error {
			case .accountNotFound, .notLogged, .networkError:
				return .warning
				
			case .serverError, .internalError:
				return .error
			}
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
			
		case .serverError, .internalError:
			return .apiError(self)
		}
	}
}

extension ChatsProviderError {
    func asWalletServiceError() -> WalletServiceError {
        switch self {
        case .notLogged:
            return .notLogged
            
        case .messageNotValid(_):
            return .notLogged
            
        case .notEnoughMoneyToSend:
            return .notEnoughMoney
            
        case .networkError:
            return .networkError
            
        case .serverError(let e as ApiServiceError):
            return .apiError(e)
            
        case .serverError(let e):
            return .internalError(message: self.message, error: e)
            
        case .accountNotFound(_):
            return .accountNotFound
            
        case .dependencyError(let message):
            return .internalError(message: message, error: nil)
            
        case .transactionNotFound(let id):
            return .transactionNotFound(reason: "\(id)")
            
        case .internalError(let error):
            return .internalError(message: self.message, error: error)
            
        case .accountNotInitiated(_):
            return .walletNotInitiated
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
protocol WalletService: class {
	// MARK: Currency
	static var currencySymbol: String { get }
	static var currencyLogo: UIImage { get }
    
    var tokenSymbol: String { get }
    var tokenName: String { get }
    var tokenLogo: UIImage { get }
	
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
	func getWalletAddress(byAdamantAddress address: String, completion: @escaping (WalletServiceResult<String>) -> Void)
}

protocol SwinjectDependentService: WalletService {
	func injectDependencies(from container: Container)
}

protocol InitiatedWithPassphraseService: WalletService {
	func initWallet(withPassphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void)
    func setInitiationFailed(reason: String)
}

protocol WalletServiceWithTransfers: WalletService {
	func transferListViewController() -> UIViewController
}

// MARK: Send

protocol WalletServiceWithSend: WalletService {
	var transactionFeeUpdated: Notification.Name { get }
	
	var transactionFee : Decimal { get }
    var commentsEnabledForRichMessages: Bool { get }
	func transferViewController() -> UIViewController
}

extension WalletServiceWithSend {
    var commentsEnabledForRichMessages: Bool {
        return true
    }
}

protocol WalletServiceSimpleSend: WalletServiceWithSend {
	func sendMoney(recipient: String, amount: Decimal, comments: String, completion: @escaping (WalletServiceResult<TransactionDetails>) -> Void)
}

protocol WalletServiceTwoStepSend: WalletServiceWithSend {
	associatedtype T: RawTransaction
	
	func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<T>) -> Void)
	func sendTransaction(_ transaction: T, completion: @escaping (WalletServiceResult<String>) -> Void)
}

protocol RawTransaction {
	var txHash: String? { get }
}
