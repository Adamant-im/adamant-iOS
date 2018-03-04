//
//  AdamantAccountService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantAccountService {
	
	// MARK: Dependencies
	
	var apiService: ApiService!
	var adamantCore: AdamantCore!
	
	
	// MARK: Properties
	
	private(set) var state: AccountServiceState = .notLogged
	private let stateSemaphore = DispatchSemaphore(value: 1)
	
	private(set) var account: Account?
	private(set) var keypair: Keypair?
	
	private func setState(_ state: AccountServiceState) {
		stateSemaphore.wait()
		self.state = state
		stateSemaphore.signal()
	}
}


// MARK: - AccountService
extension AdamantAccountService: AccountService {
	// MARK: Update logged account info
	func update() {
		stateSemaphore.wait()
		
		switch state {
		case .notLogged:
			fallthrough
		
		case .isLoggingIn:
			fallthrough
		
		case .updating:
			stateSemaphore.signal()
			return
			
		case .loggedIn:
			break
		}
		
		state = .updating
		stateSemaphore.signal()
		
		guard let loggedAccount = account else {
			return
		}
		
		apiService.getAccount(byPublicKey: loggedAccount.publicKey) { [weak self] result in
			switch result {
			case .success(let account):
				guard let acc = self?.account, acc.address == account.address else {
					// User has logged out, we not interested anymore
					self?.setState(.notLogged)
					return
				}
				
				if loggedAccount.balance != account.balance {
					self?.account = account
					NotificationCenter.default.post(name: Notification.Name.adamantAccountDataUpdated, object: nil)
				}
				
				self?.setState(.loggedIn)
				
			case .failure(let error):
				print("Error update account: \(String(describing: error))")
			}
		}
	}
	
	// Create new account
	func createAccount(with passphrase: String, completion: @escaping (AccountServiceResult) -> Void) {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
			completion(.failure(.invalidPassphrase))
			return
		}
		
		guard let publicKey = adamantCore.createKeypairFor(passphrase: passphrase)?.publicKey else {
			completion(.failure(.internalError(message: "Can't create key for passphrase", error: nil)))
			return
		}
		
		self.apiService.getAccount(byPublicKey: publicKey) { [weak self] result in
			switch result {
			case .success(_):
				completion(.failure(.wrongPassphrase))
				
			case .failure(_):
				if let apiService = self?.apiService {
					apiService.newAccount(byPublicKey: publicKey) { result in
						switch result {
						case .success(let account):
							completion(.success(account: account))
							
						case .failure(let error):
							completion(.failure(.apiError(error: error)))
						}
					}
				} else {
					completion(.failure(.internalError(message: "A bad thing happened", error: nil)))
				}
			}
		}
	}
	
	// MARK: Login with passphrase
	func login(with passphrase: String, completion: @escaping (AccountServiceResult) -> Void) {
		guard AdamantUtilities.validateAdamantPassphrase(passphrase: passphrase) else {
			completion(.failure(.invalidPassphrase))
			return
		}
		
		guard let keypair = adamantCore.createKeypairFor(passphrase: passphrase) else {
			completion(.failure(.internalError(message: "Failed to generate keypair for passphrase", error: nil)))
			return
		}
		
		stateSemaphore.wait()
		switch state {
		case .isLoggingIn:
			stateSemaphore.signal()
			completion(.failure(.internalError(message: "Service is busy", error: nil)))
			return
			
		case .updating:
			fallthrough
			
		// Logout first
		case .loggedIn:
			logout(lockSemaphore: false)
			
		// Go login
		case .notLogged:
			break
		}
		
		state = .isLoggingIn
		stateSemaphore.signal()
		
		apiService.getAccount(byPublicKey: keypair.publicKey) { result in
			switch result {
			case .success(let account):
				self.account = account
				self.keypair = keypair
				NotificationCenter.default.post(name: Notification.Name.adamantUserLoggedIn, object: nil)
				self.setState(.loggedIn)
				completion(.success(account: account))
				
			case .failure(let error):
				self.setState(.notLogged)
				
				switch error {
				case .accountNotFound:
					completion(.failure(.wrongPassphrase))
					
				default:
					completion(.failure(.apiError(error: error)))
				}
			}
		}
	}
	
	// MARK: Logout
	func logout() {
		logout(lockSemaphore: true)
	}
	
	private func logout(lockSemaphore: Bool) {
		let wasLogged = account != nil
		account = nil
		keypair = nil
		
		if lockSemaphore {
			setState(.notLogged)
		} else {
			state = .notLogged
		}
		
		if wasLogged {
			NotificationCenter.default.post(name: Notification.Name.adamantUserLoggedOut, object: nil)
		}
	}
}
