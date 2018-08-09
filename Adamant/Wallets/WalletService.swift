//
//  Wallet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

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

enum WalletServiceError: Error {
	case notLogged
	case notEnoughtMoney
	case networkError
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
			
		case .remoteServiceError(let message):
			return String.adamantLocalized.sharedErrors.remoteServerError(message: message)
			
		case .apiError(let error):
			return error.localized
			
		case .internalError(let message, _):
			return String.adamantLocalized.sharedErrors.internalError(message: message)
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
		case .notLogged, .notEnoughtMoney, .networkError:
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


// MARK: - Notifications
extension AdamantUserInfoKey {
	struct WalletService {
		static let wallet = "Adamant.WalletService.wallet"
		
		private init() {}
	}
}


// MARK: - Wallet Service
protocol WalletService: class {
	// MARK: Currency
	static var currencySymbol: String { get }
	static var currencyLogo: UIImage { get }
	
	// MARK: Notifications
	
	/// Wallet updated.
	/// UserInfo contains new wallet at AdamantUserInfoKey.WalletService.wallet
	static var walletUpdatedNotification: Notification.Name { get }
	
	/// Enabled state changed
	static var serviceEnabledChanged: Notification.Name { get }
	
	// MARK: State
	var wallet: WalletAccount? { get }
	var state: WalletServiceState { get }
	var enabled: Bool { get }
	
	// MARK: Logic
	func update()
	
	// MARK: Tools
	func validate(address: String) -> AddressValidationResult
}

protocol WalletInitiatedWithPassphrase: WalletService {
	func initWallet(withPassphrase: String, completion: @escaping (WalletServiceResult<WalletAccount>) -> Void)
}

protocol WalletWithTransfers: WalletService {
	var transactionFee: Decimal { get }
	func transfer()
}
