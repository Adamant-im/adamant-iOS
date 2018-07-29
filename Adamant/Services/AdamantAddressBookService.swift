//
//  AdamantAddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium

class AdamantAddressBookService: AddressBookService {
	let addressBookKey = "contact_list"
    let waitTime: TimeInterval = 60.0 // in sec
	
	
    // MARK: - Dependencies
	
	var apiService: ApiService!
    var adamantCore: AdamantCore!
    var accountService: AccountService!
	var dialogService: DialogService!
	
	
    // MARK: - Properties
	
	var addressBook: [String:String] = [String:String]()
    
    private(set) var hasChanges = false
    private var timer: Timer?
	private var isChangedSemaphore = DispatchSemaphore(value: 1)
	
	
	// MARK: - Lifecycle
	init() {
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedIn, object: nil, queue: nil) { [weak self] _ in
			self?.update(nil)
		}
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: nil) { [weak self] _ in
			self?.addressBook.removeAll()
			
			let semaphore = self?.isChangedSemaphore // Hold reference
			semaphore?.wait()
			
			self?.hasChanges = false
			self?.timer?.invalidate()
			self?.timer = nil
			
			semaphore?.signal()
		}
	}
	
	// MARK: - Setting
	
	func set(name: String, for address: String) {
		isChangedSemaphore.wait()
		
		guard addressBook[address] == nil || addressBook[address] != name else {
			return
		}
		
		let changes: [AddressBookChange]
		
		if name.count > 0 {
			if let prevName = addressBook[address] {
				if prevName == name {
					return
				}
				
				changes = [AddressBookChange.updated(address: address, name: name)]
			} else {
				changes = [AddressBookChange.newName(address: address, name: name)]
			}
			
			addressBook[address] = name
		} else {
			addressBook.removeValue(forKey: address)
			changes = [AddressBookChange.removed(address: address)]
		}
		
		hasChanges = true
		
		if timer != nil {
			timer?.invalidate()
			timer = nil
		}
		
		timer = Timer.scheduledTimer(withTimeInterval: waitTime, repeats: false) { [weak self] _ in
			self?.saveAddressBook { result in
				switch result {
				case .success:
					self?.hasChanges = false
					
				case .failure(let error):
					self?.dialogService.showRichError(error: error)
				}
				
				self?.timer = nil
			}
		}
		
		isChangedSemaphore.signal()
		
		NotificationCenter.default.post(name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
										object: self,
										userInfo: [AdamantUserInfoKey.AddressBook.changes: changes])
	}
	
	
	// MARK: - Updating
	
	func update() {
		update(nil)
	}
	
	func update(_ completion: ((AddressBookServiceResult) -> Void)?) {
		getAddressBook { result in
			switch result {
			case .success(let book):
				if self.addressBook != book {
					self.isChangedSemaphore.wait()
					
					var localBook = self.addressBook
					var changes = [AddressBookChange]()
					
					for (address, name) in book {
						if let localName = localBook[address] {
							if localName != name {
								localBook[address] = name
								changes.append(AddressBookChange.updated(address: address, name: name))
							}
						} else {
							localBook[address] = name
							changes.append(AddressBookChange.newName(address: address, name: name))
						}
					}
					
					self.addressBook = localBook
					
					self.isChangedSemaphore.signal()
					
					NotificationCenter.default.post(name: Notification.Name.AdamantAddressBookService.addressBookUpdated,
													object: self,
													userInfo: [AdamantUserInfoKey.AddressBook.changes: changes])
				}
				
				completion?(.success)
				
			case .failure(let error):
				completion?(.failure(error))
			}
		}
	}
	
	
	// MARK: - Saving
	
	func saveIfNeeded() {
		isChangedSemaphore.wait()
		
		guard hasChanges else {
			isChangedSemaphore.signal()
			return
		}
		
		isChangedSemaphore.signal()
		
		if let timer = timer {
			timer.invalidate()
			self.timer = nil
		}
		
		saveAddressBook { [unowned self] result in
			switch result {
			case .success:
				self.isChangedSemaphore.wait()
				self.hasChanges = false
				self.isChangedSemaphore.signal()
				
			case .failure(let error):
				self.dialogService.showRichError(error: error)
			}
		}
	}
	
	private func saveAddressBook(completion: @escaping (AddressBookServiceResult) -> Void) {
		guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
			completion(.failure(.notLogged))
			return
		}
		
		guard loggedAccount.balance >= AdamantApiService.KVSfee else {
			completion(.failure(.notEnoughtMoney))
			return
		}
		
		let address = loggedAccount.address
		
		// MARK: 1. Pack and ecode address book
		let packed = AdamantAddressBookService.packAddressBook(book: self.addressBook)
		if let encodeResult = adamantCore.encodeValue(packed, privateKey: keypair.privateKey) {
			let value = JSONStringify(value: ["message": encodeResult.message,
											  "nonce": encodeResult.nonce] as AnyObject)
			
			// MARK: 2. Submit to KVS
			apiService.store(key: addressBookKey, value: value, type: .keyValue, sender: address, keypair: keypair) { (result) in
				switch result {
				case .success:
					completion(.success)
					
				case .failure(let error):
					completion(.failure(.apiServiceError(error: error)))
				}
			}
		}
	}
	
	
	// MARK: - Getting address book
	private enum GetAddressBookResult {
		case success([String:String])
		case failure(AddressBookServiceError)
	}
	
    private func getAddressBook(completion: @escaping (GetAddressBookResult) -> Void) {
        guard let loggedAccount = accountService.account, let keypair = accountService.keypair else {
            completion(.failure(.notLogged))
            return
        }
		
		let address = loggedAccount.address
        
        apiService.get(key: addressBookKey, sender: address) { [weak self] (result) in
            switch result {
            case .success(let rawValue):
				guard let value = rawValue, let object = value.toDictionary() else {
					completion(.failure(.internalError(message: "Processing error", error: nil)))
					return
				}
				
				guard let message = object["message"] as? String,
					let nonce = object["nonce"] as? String else {
					completion(.failure(.internalError(message: "Processing error", error: nil)))
					return
				}
				
				// MARK: Encoding
				if let result = self?.adamantCore.decodeValue(rawMessage: message, rawNonce: nonce, privateKey: keypair.privateKey),
					let value = result.matches(for: "\\{.*\\}").first,
					let object = value.toDictionary(),
					let rawAddressBook = object["payload"] as? [String:Any] {
					let book = AdamantAddressBookService.processAddressBook(rawBook: rawAddressBook)
					completion(.success(book))
				} else {
					completion(.failure(.internalError(message: "Encoding error", error: nil)))
				}
                
            case .failure(let error):
				completion(.failure(.apiServiceError(error: error)))
            }
        }
    }
}


// MARK: - Tools
extension AdamantAddressBookService {
	private static func processAddressBook(rawBook: [String:Any]) -> [String:String] {
		var processedBook = [String:String]()
		for key in rawBook.keys {
			if let value = rawBook[key] as? [String:Any], let displayName = value["displayName"] as? String {
				processedBook[key] = displayName
			}
		}
		return processedBook
	}
	
	private static func packAddressBook(book: [String:String]) -> [String:Any] {
		var processedBook = [String:Any]()
		for key in book.keys {
			if let value = book[key] {
				processedBook[key] = ["displayName": value]
			}
		}
		return processedBook
	}
}
