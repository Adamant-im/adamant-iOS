//
//  AdamantAccountsProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Provider
class AdamantAccountsProvider: AccountsProvider {
	struct KnownContact {
		let address: String
		let name: String
		let avatar: String?
		let isReadonly: Bool
		let isHidden: Bool
		
		fileprivate init(contact: AdamantContacts) {
			self.address = contact.address
			self.name = contact.name
			self.avatar = contact.avatar
			self.isReadonly = contact.isReadonly
			self.isHidden = contact.isHidden
		}
	}
    
    private enum GetAccountResult {
        case core(CoreDataAccount)
        case dummy(DummyAccount)
        case notFound
    }
	
	// MARK: Dependencies
	var stack: CoreDataStack!
	var apiService: ApiService!
	var addressBookService: AddressBookService!
	
	
	// MARK: Properties
	private let knownContacts: [String:KnownContact]
	
	
	// MARK: Lifecycle
	init() {
		let ico = KnownContact(contact: AdamantContacts.adamantIco)
		let bounty = KnownContact(contact: AdamantContacts.adamantBountyWallet)
		let iosSupport = KnownContact(contact: AdamantContacts.iosSupport)
		
		self.knownContacts = [
			AdamantContacts.adamantIco.address: ico,
			AdamantContacts.adamantIco.name: ico,
			AdamantContacts.adamantBountyWallet.address: bounty,
			AdamantContacts.adamantBountyWallet.name: bounty,
			AdamantContacts.iosSupport.address: iosSupport
		]
		
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAddressBookService.addressBookUpdated, object: nil, queue: nil) { [weak self] notification in
			guard let changes = notification.userInfo?[AdamantUserInfoKey.AddressBook.changes] as? [AddressBookChange],
				let viewContext = self?.stack.container.viewContext else {
				return
			}
			
			DispatchQueue.global(qos: .utility).async {
				let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
				context.parent = viewContext
				
				let requestSingle = NSFetchRequest<CoreDataAccount>(entityName: CoreDataAccount.entityName)
				requestSingle.fetchLimit = 1
				
				// Process changes
				for change in changes {
					switch change {
					case .newName(let address, let name), .updated(let address, let name):
						let predicate = NSPredicate(format: "address == %@", address)
						requestSingle.predicate = predicate
						
						guard let result = try? context.fetch(requestSingle), let account = result.first else {
							continue
						}
						
						account.name = name
						account.chatroom?.title = name
						
					case .removed(let address):
						let predicate = NSPredicate(format: "address == %@", address)
						requestSingle.predicate = predicate
						
						guard let result = try? context.fetch(requestSingle), let account = result.first else {
							continue
						}
						
						account.name = nil
						account.chatroom?.title = nil
					}
				}
				
				if context.hasChanges {
					DispatchQueue.main.async {
						try? context.save()
					}
				}
			}
		}
	}
	
	
	// MARK: Threading
	private let queue = DispatchQueue(label: "im.adamant.accounts.getAccount", qos: .utility, attributes: [.concurrent])
	
	private var requestGroups = [String:DispatchGroup]()
	private let groupsSemaphore = DispatchSemaphore(value: 1)
    
    private func removeSafeFromRequests(_ address: String) {
        if Thread.isMainThread {
            let group = DispatchGroup()
            
            DispatchQueue.global(qos: .utility).async {
                defer { group.leave() }
                group.enter()
                self.groupsSemaphore.wait()
                self.requestGroups.removeValue(forKey: address)
                self.groupsSemaphore.signal()
                group.wait()
            }
        } else {
            groupsSemaphore.wait()
            requestGroups.removeValue(forKey: address)
            groupsSemaphore.signal()
        }
    }
	
	private func getAccount(byPredicate predicate: NSPredicate, context: NSManagedObjectContext? = nil) -> GetAccountResult {
		let request = NSFetchRequest<BaseAccount>(entityName: BaseAccount.baseEntityName)
		request.fetchLimit = 1
		request.predicate = predicate
		
		var acc = (try? (context ?? stack.container.viewContext).fetch(request))?.first
		
        if let context = context {
            acc = (try? context.fetch(request))?.first
        } else {
            if Thread.isMainThread {
                acc = (try? stack.container.viewContext.fetch(request))?.first
            } else {
                DispatchQueue.main.sync {
                    acc = (try? stack.container.viewContext.fetch(request))?.first
                }
            }
        }
        
		if Thread.isMainThread {
			acc = (try? (context ?? stack.container.viewContext).fetch(request))?.first
		} else {
			DispatchQueue.main.sync {
				acc = (try? (context ?? stack.container.viewContext).fetch(request))?.first
			}
		}
		
        switch acc {
        case let core as CoreDataAccount:
            return .core(core)
            
        case let dummy as DummyAccount:
            return .dummy(dummy)
            
        case .some(_), nil:
            return .notFound
        }
	}
}


// MARK: - Getting account info from API
extension AdamantAccountsProvider {
	/// Check, if we already have account
	///
	/// - Parameter address: account's address
	/// - Returns: do have acccount, or not
	func hasAccount(address: String, completion: @escaping (Bool) -> Void) {
		queue.async {
			self.groupsSemaphore.wait()
			
			if let group = self.requestGroups[address] {
				self.groupsSemaphore.signal()
				group.wait()
			} else {
				self.groupsSemaphore.signal()
			}
			
			let account = self.getAccount(byPredicate: NSPredicate(format: "address == %@", address))
			
            switch account {
            case .core(_), .dummy(_): completion(true)
            case .notFound: return completion(false)
            }
		}
	}
	
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - address: address of an account
	///   - completion: returns Account created in viewContext
	func getAccount(byAddress address: String, completion: @escaping (AccountsProviderResult) -> Void) {
		let validation = AdamantUtilities.validateAdamantAddress(address: address)
		if validation == .invalid {
			completion(.invalidAddress(address: address))
			return
		}
        
        let context = stack.container.viewContext
		
		// Go background, to not to hang threads (especially main) on semaphores and dispatch groups
		queue.async {
			self.groupsSemaphore.wait() // 1
			
			// If there is already request for a this address, wait
			if let group = self.requestGroups[address] {
				self.groupsSemaphore.signal() // 1
				group.wait()
				self.groupsSemaphore.wait() // 2
			}
            
			// Check if there is an account, that we are looking for
            let dummy: DummyAccount?
            switch self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
            case .core(let account):
                self.groupsSemaphore.signal() // 1 or 2
                completion(.success(account))
                return
                
            case .dummy(let account):
                dummy = account
                
            case .notFound:
                dummy = nil
            }
			
			// No, we need to get one
			let group = DispatchGroup()
			self.requestGroups[address] = group
			group.enter()
            
			self.groupsSemaphore.signal() // 1 or 2
			
			switch validation {
			case .valid:
				self.apiService.getAccount(byAddress: address) { result in
					switch result {
					case .success(let account):
                        guard account.publicKey != nil else {
                            self.removeSafeFromRequests(address)
                            group.leave()
                            
                            if let dummy = dummy {
                                completion(.dummy(dummy))
                            } else {
                                completion(.notInitiated(address: address))
                            }
                            return
                        }
                        
                        var coreAccount: CoreDataAccount! = nil
                        DispatchQueue.main.sync {
                            coreAccount = self.createCoreDataAccount(from: account,  context: context)
                            
                            if let dummy = dummy {
                                coreAccount.name = dummy.name
                                
                                if let transfers = dummy.transfers {
                                    dummy.removeFromTransfers(transfers)
                                    coreAccount.addToTransfers(transfers)
                                    
                                    if let chatroom = coreAccount.chatroom {
                                        chatroom.addToTransactions(transfers)
                                        chatroom.updateLastTransaction()
                                    }
                                }
                                
                                context.delete(dummy)
                            }
                            
                            try? context.save()
                        }
                        
                        self.removeSafeFromRequests(address)
                        group.leave()
                        
                        completion(.success(coreAccount))
						
					case .failure(let error):
                        self.removeSafeFromRequests(address)
                        group.leave()
                        
						switch error {
						case .accountNotFound:
                            if let dummy = dummy {
                                completion(.dummy(dummy))
                            } else {
                                completion(.notFound(address: address))
                            }
							
						case .networkError(let error):
                            completion(.networkError(error))
							
						default:
							completion(.serverError(error))
						}
					}
				}
				
			case .system:
				let coreAccount = self.createCoreDataAccount(with: address, publicKey: "")
                self.removeSafeFromRequests(address)
                group.leave()
                
				completion(.success(coreAccount))
				
			case .invalid:
                self.removeSafeFromRequests(address)
                group.leave()
                
				completion(.invalidAddress(address: address))
			}
		}
	}
	
	
	
	/*
	
	Запросы на аккаунт по publicId и запросы на аккаунт по address надо взаимно согласовывать. Иначе может случиться такое, что разные службы запросят один и тот же аккаунт через разные методы - он будет добавлен дважды.
	
	/// Get account info from servier.
	///
	/// - Parameters:
	///   - publicKey: publicKey of an account
	///   - completion: returns Account created in viewContext
	func getAccount(byPublicKey publicKey: String, completion: @escaping (AccountsProviderResult) -> Void) {
		// Go background, to not to hang threads (especially main) on semaphores and dispatch groups
		queue.async {
			self.groupsSemaphore.wait()
			
			// If there is already request for a this address, wait
			if let group = self.requestGroups[publicKey] {
				self.groupsSemaphore.signal()
				group.wait()
				self.groupsSemaphore.wait()
			}
			
			
			// Check account
			if let account = self.getAccount(byPredicate: NSPredicate(format: "publicKey == %@", publicKey)) {
				self.groupsSemaphore.signal()
				completion(.success(account))
				return
			}
			
			// Not found, maybe on server?
			let group = DispatchGroup()
			self.requestGroups[publicKey] = group
			group.enter()
			self.groupsSemaphore.signal()
			
			self.apiService.getAccount(byPublicKey: publicKey) { result in
				defer {
					self.groupsSemaphore.wait()
					self.requestGroups.removeValue(forKey: publicKey)
					self.groupsSemaphore.signal()
					group.leave()
				}
				
				switch result {
				case .success(let account):
					let coreAccount = self.createCoreDataAccount(from: account)
					completion(.success(coreAccount))
					
				case .failure(let error):
					switch error {
					case .accountNotFound:
						completion(.notFound)
						
					default:
						completion(.serverError(error))
					}
				}
			}
		}
	}

	*/
	
	private func createCoreDataAccount(with address: String, publicKey: String) -> CoreDataAccount {
		let coreAccount: CoreDataAccount
		if Thread.isMainThread {
			coreAccount = createCoreDataAccount(with: address, publicKey: publicKey, context: stack.container.viewContext)
		} else {
			var acc: CoreDataAccount!
			DispatchQueue.main.sync {
				acc = createCoreDataAccount(with: address, publicKey: publicKey, context: stack.container.viewContext)
			}
			coreAccount = acc
		}
		
		return coreAccount
	}
	
	private func createCoreDataAccount(from account: AdamantAccount) -> CoreDataAccount {
		let coreAccount: CoreDataAccount
		if Thread.isMainThread {
			coreAccount = createCoreDataAccount(from: account, context: stack.container.viewContext)
		} else {
			var acc: CoreDataAccount!
			DispatchQueue.main.sync {
				acc = createCoreDataAccount(from: account, context: stack.container.viewContext)
			}
			coreAccount = acc
		}
		
		return coreAccount
	}
	
	private func createCoreDataAccount(from account: AdamantAccount, context: NSManagedObjectContext) -> CoreDataAccount {
		let coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: context)
		coreAccount.address = account.address
		coreAccount.publicKey = account.publicKey
		
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.updatedAt = NSDate()
		
		coreAccount.chatroom = chatroom
		
		
		if let acc = knownContacts[account.address] {
			coreAccount.name = acc.name
			coreAccount.avatar = acc.avatar
			coreAccount.isSystem = true
			chatroom.isReadonly = acc.isReadonly
			chatroom.isHidden = acc.isHidden
			chatroom.title = acc.name
		}
		
		if let address = coreAccount.address, let name = addressBookService.addressBook[address] {
			coreAccount.name = name
			chatroom.title = name
		}
		
		return coreAccount
	}
	
	private func createCoreDataAccount(with address: String, publicKey: String, context: NSManagedObjectContext) -> CoreDataAccount {
		let coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: context)
		coreAccount.address = address
		coreAccount.publicKey = publicKey
		
		let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
		chatroom.updatedAt = NSDate()
		
		coreAccount.chatroom = chatroom
		
		if let acc = knownContacts[address] {
			coreAccount.name = acc.name
			coreAccount.avatar = acc.avatar
			coreAccount.isSystem = true
			chatroom.isReadonly = acc.isReadonly
			chatroom.title = acc.name
		}
		
		return coreAccount
	}
}


// MARK: - Dummy
extension AdamantAccountsProvider {
    func getDummyAccount(for address: String, completion: @escaping (AccountsProviderDummyAccountResult) -> Void) {
        let validation = AdamantUtilities.validateAdamantAddress(address: address)
        if validation == .invalid {
            completion(.invalidAddress(address: address))
            return
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        queue.async {
            self.groupsSemaphore.wait()
            
            if let group = self.requestGroups[address] {
                self.groupsSemaphore.signal()
                group.wait()
            } else {
                self.groupsSemaphore.signal()
            }
            
            switch self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
            case .core(let account):
                completion(.foundRealAccount(account))
                
            case .dummy(let account):
                completion(.success(account))
                
            case .notFound:
                let dummy = DummyAccount(entity: DummyAccount.entity(), insertInto: context)
                dummy.address = address
                
                do {
                    try context.save()
                    completion(.success(dummy))
                } catch {
                    completion(.internalError(error))
                }
            }
        }
    }
}
