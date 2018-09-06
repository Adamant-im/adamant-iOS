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

enum WalletServiceState {
	case notInitiated, initiated, updated, updating
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
	case notEnoughtMoney
	case networkError
	case accountNotFound
	case walletNotInitiated
	case invalidAmount(Decimal)
	case remoteServiceError(message: String)
	case apiError(ApiServiceError)
	case internalError(message: String, error: Error?)
}

extension WalletServiceError: RichError {
	var message: String {
		switch self {
		case .notLogged:
			return String.adamantLocalized.sharedErrors.userNotLogged
			
		case .notEnoughtMoney:
			return NSLocalizedString("WalletServices.SharedErrors.NotEnoughtMoney", comment: "Wallet Services: Shared error, user do not have enought money.")
			
		case .networkError:
			return String.adamantLocalized.sharedErrors.networkError
			
		case .accountNotFound:
			return String.adamantLocalized.transfer.accountNotFound
			
		case .walletNotInitiated:
			return "Кошелёк ещё не создан для этого аккаунта"
			
		case .remoteServiceError(let message):
			return String.adamantLocalized.sharedErrors.remoteServerError(message: message)
			
		case .apiError(let error):
			return error.localized
			
		case .internalError(let message, _):
			return String.adamantLocalized.sharedErrors.internalError(message: message)
			
		case .invalidAmount(let amount):
			return "Неверное количество для перевода: \(amount)"
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
		case .notLogged, .notEnoughtMoney, .networkError, .accountNotFound, .invalidAmount, .walletNotInitiated:
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


// MARK: - Notifications
extension AdamantUserInfoKey {
	struct WalletService {
		static let wallet = "Adamant.WalletService.wallet"
		
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
	
	// MARK: Notifications
	
	/// Wallet updated.
	/// UserInfo contains new wallet at AdamantUserInfoKey.WalletService.wallet
	var walletUpdatedNotification: Notification.Name { get }
	
	/// Enabled state changed
	var serviceEnabledChanged: Notification.Name { get }
	
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
}

protocol WalletServiceWithTransfers: WalletService {
	func transferListViewController() -> UIViewController
}

// MARK: Send

protocol WalletServiceWithSend: WalletService {
	var transactionFeeUpdated: Notification.Name { get }
	
	var transactionFee : Decimal { get }
	func transferViewController() -> UIViewController
}

protocol WalletServiceSimpleSend: WalletServiceWithSend {
	func sendMoney(recipient: String, amount: Decimal, comments: String, completion: @escaping (WalletServiceSimpleResult) -> Void)
}

protocol WalletServiceTwoStepSend: WalletServiceWithSend {
	associatedtype T: RawTransaction
	
	func createTransaction(recipient: String, amount: Decimal, comments: String, completion: @escaping (WalletServiceResult<T>) -> Void)
	func sendTransaction(_ transaction: T, completion: @escaping (WalletServiceResult<String>) -> Void)
}

protocol RawTransaction {
	var txHash: String? { get }
}
