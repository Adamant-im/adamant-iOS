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
@MainActor
final class AdamantAccountsProvider: AccountsProvider {
    struct KnownContact {
        let address: String
        let name: String
        let avatar: String?
        let isReadonly: Bool
        let isHidden: Bool
        let isSystem: Bool
        let publicKey: String?
        
        fileprivate init(contact: AdamantContacts) {
            self.address = contact.address
            self.name = contact.name
            self.avatar = contact.avatar.isEmpty ? nil : contact.avatar
            self.isReadonly = contact.isReadonly
            self.isHidden = contact.isHidden
            self.isSystem = contact.isSystem
            self.publicKey = contact.publicKey
        }
    }
    
    private enum GetAccountResult {
        case core(CoreDataAccount)
        case dummy(DummyAccount)
        case notFound
    }
    
    // MARK: Dependencies
    @MainActor private let stack: CoreDataStack
    private let apiService: ApiService
    private let addressBookService: AddressBookService
    
    // MARK: Properties
    private let knownContacts: [String:KnownContact]
    
    // MARK: Lifecycle
    nonisolated init(
        stack: CoreDataStack,
        apiService: ApiService,
        addressBookService: AddressBookService
    ) {
        self.stack = stack
        self.apiService = apiService
        self.addressBookService = addressBookService
        
        let ico = KnownContact(contact: AdamantContacts.adamantIco)
        let bounty = KnownContact(contact: AdamantContacts.adamantBountyWallet)
        let welcome = KnownContact(contact: AdamantContacts.adamantWelcomeWallet)
        let newBounty = KnownContact(contact: AdamantContacts.adamantNewBountyWallet)
        let iosSupport = KnownContact(contact: AdamantContacts.iosSupport)
        
        let adamantExchange = KnownContact(contact: AdamantContacts.adamantExchange)
        let betOnBitcoin = KnownContact(contact: AdamantContacts.betOnBitcoin)
        let adelina = KnownContact(contact: AdamantContacts.adelina)
        
        let donate = KnownContact(contact: AdamantContacts.donate)
        
        self.knownContacts = [
            AdamantContacts.adamantIco.address: ico,
            AdamantContacts.adamantIco.name: ico,
            AdamantContacts.adamantBountyWallet.address: bounty,
            AdamantContacts.adamantBountyWallet.name: bounty,
            AdamantContacts.adamantNewBountyWallet.address: newBounty,
            AdamantContacts.iosSupport.address: iosSupport,
            
            AdamantContacts.adamantExchange.address: adamantExchange,
            AdamantContacts.adamantExchange.name: adamantExchange,
            
            AdamantContacts.betOnBitcoin.address: betOnBitcoin,
            AdamantContacts.betOnBitcoin.name: betOnBitcoin,
            
            AdamantContacts.donate.address: donate,
            
            AdamantContacts.adamantWelcomeWallet.address: welcome,
            AdamantContacts.adamantWelcomeWallet.name: welcome,
            
            AdamantContacts.adelina.address: adelina,
            AdamantContacts.adelina.name: adelina
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
    
    private func getAccount(byPredicate predicate: NSPredicate, context: NSManagedObjectContext? = nil) async -> GetAccountResult {
        let request = NSFetchRequest<BaseAccount>(entityName: BaseAccount.baseEntityName)
        request.fetchLimit = 1
        request.predicate = predicate
        
        var acc: BaseAccount?
        
        if let context = context {
            // viewContext only on MainThread
            if context == stack.container.viewContext {
                DispatchQueue.onMainSync {
                    acc = (try? context.fetch(request))?.first
                }
            } else {
                acc = (try? context.fetch(request))?.first
            }
        } else {
            // viewContext only on MainThread
            DispatchQueue.onMainSync {
                acc = (try? stack.container.viewContext.fetch(request))?.first
            }
        }
        
        switch acc {
        case let core as CoreDataAccount:
            return .core(core)
            
        case let dummy as DummyAccount:
            return .dummy(dummy)
            
        case .some, nil:
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
    
    func hasAccount(address: String) async -> Bool {
        let account = await self.getAccount(byPredicate: NSPredicate(format: "address == %@", address))
        
        switch account {
        case .core, .dummy: return true
        case .notFound: return false
        }
    }
    
    /// Get account info from server.
    ///
    /// - Parameters:
    ///   - address: address of an account
    ///   - completion: returns Account created in viewContext
    
    func getAccount(byAddress address: String) async throws -> CoreDataAccount {
        let validation = AdamantUtilities.validateAdamantAddress(address: address)
        if validation == .invalid {
            throw AccountsProviderError.invalidAddress(address: address)
        }
        
        // Check if there is an account, that we are looking for
        let dummy: DummyAccount?
        switch await self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
        case .core(let account):
            return account
        case .dummy(let account):
            dummy = account
        case .notFound:
            dummy = nil
        }
        
        switch validation {
        case .valid:
            do {
                var account = try await apiService.getAccount(byAddress: address)
                guard account.publicKey != nil else {
                    account.publicKey = "dummy\(address)"
                    account.isDummy = true
                    let coreAccount = await createAndSaveCoreDataAccount(
                        from: account,
                        dummy: dummy,
                        in: stack.container.viewContext
                    )
                    
                    return coreAccount
                }
                
                let coreAccount = await createAndSaveCoreDataAccount(
                    from: account,
                    dummy: dummy,
                    in: stack.container.viewContext
                )
                
                return coreAccount
            } catch let error as ApiServiceError {
                switch error {
                case .accountNotFound:
                    if let dummy = dummy {
                        throw AccountsProviderError.dummy(dummy)
                    } else {
                        throw AccountsProviderError.notFound(address: address)
                    }
                    
                case .networkError(let error):
                    throw AccountsProviderError.networkError(error)
                    
                default:
                    throw AccountsProviderError.serverError(error)
                }
            }
        case .system:
            let coreAccount = await createCoreDataAccount(with: address, publicKey: "")
            return coreAccount
        case .invalid:
            throw AccountsProviderError.invalidAddress(address: address)
        }
    }
    
    /// Get account info from server or create instantly
    ///
    /// - Parameters:
    ///   - address: address of an account
    ///   - publicKey: publicKey of an account
    ///   - completion: returns Account created in viewContext
    
    func getAccount(
        byAddress address: String,
        publicKey: String
    ) async throws -> CoreDataAccount {
        let validation = AdamantUtilities.validateAdamantAddress(address: address)
        if validation == .invalid {
            throw AccountsProviderError.invalidAddress(address: address)
        }
        
        if publicKey.isEmpty {
            return try await getAccount(byAddress: address)
        }
        
        let context = stack.container.viewContext
        
        // Check if there is an account, that we are looking for
        let dummy: DummyAccount?
        switch await self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
        case .core(let account):
            return account
        case .dummy(let account):
            dummy = account
        case .notFound:
            dummy = nil
        }
        
        switch validation {
        case .valid:
            let coreAccount = await createAndSaveCoreDataAccount(
                for: address,
                publicKey: publicKey,
                dummy: dummy, in: context
            )
            
            return coreAccount
        case .system:
            let coreAccount = await createCoreDataAccount(with: address, publicKey: "")
            return coreAccount
        case .invalid:
            throw AccountsProviderError.invalidAddress(address: address)
        }
    }
    
    private func createAndSaveCoreDataAccount(
        for address: String,
        publicKey: String,
        dummy: DummyAccount?,
        in context: NSManagedObjectContext
    ) async -> CoreDataAccount {
        let result = await getAccount(byPredicate: NSPredicate(format: "address == %@", address))
        if case .core(let account) = result {
            return account
        }
        
        let coreAccount = await self.createCoreDataAccountIfNeeded(
            with: address,
            publicKey: publicKey,
            context: context
        )
        
        if let dummy = dummy {
            coreAccount.name = dummy.name
            
            if let transfers = dummy.transfers {
                dummy.removeFromTransfers(transfers)
                coreAccount.addToTransfers(transfers)
                
                if let chatroom = coreAccount.chatroom {
                    chatroom.addToTransactions(transfers)
                    await chatroom.updateLastTransaction()
                }
            }
            context.delete(dummy)
        }
        
        try? context.save()
        return coreAccount
    }
    
    private func createAndSaveCoreDataAccount(
        from account: AdamantAccount,
        dummy: DummyAccount?,
        in context: NSManagedObjectContext
    ) async -> CoreDataAccount {
        let result = await getAccount(byPredicate: NSPredicate(format: "address == %@", account.address))
        if case .core(let account) = result {
            return account
        }
        
        let coreAccount = await self.createCoreDataAccount(from: account, context: context)
        
        coreAccount.isDummy = account.isDummy
        
        if let dummy = dummy {
            coreAccount.name = dummy.name
            
            if let transfers = dummy.transfers {
                dummy.removeFromTransfers(transfers)
                coreAccount.addToTransfers(transfers)
                
                if let chatroom = coreAccount.chatroom {
                    chatroom.addToTransactions(transfers)
                    await chatroom.updateLastTransaction()
                }
            }
            context.delete(dummy)
        }
        
        try? context.save()
        return coreAccount
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
    
    private func createCoreDataAccountIfNeeded(
        with address: String,
        publicKey: String,
        context: NSManagedObjectContext
    ) async -> CoreDataAccount {
        let result = await getAccount(byPredicate: NSPredicate(format: "address == %@", address))
        if case .core(let account) = result {
            return account
        }
        
        let coreAccount = createCoreDataAccount(
            with: address,
            publicKey: publicKey,
            context: context
        )
        return coreAccount
    }
    
    private func createCoreDataAccount(
        with address: String,
        publicKey: String
    ) async -> CoreDataAccount {
        let result = await getAccount(byPredicate: NSPredicate(format: "address == %@", address))
        if case .core(let account) = result {
            return account
        }
        
        let coreAccount = createCoreDataAccount(
            with: address,
            publicKey: publicKey,
            context: stack.container.viewContext
        )
        return coreAccount
    }
    
    private func createCoreDataAccount(from account: AdamantAccount) async -> CoreDataAccount {
        return await createCoreDataAccount(from: account, context: stack.container.viewContext)
    }
    
    private func createCoreDataAccount(
        from account: AdamantAccount,
        context: NSManagedObjectContext
    ) async -> CoreDataAccount {
        let result = await getAccount(byPredicate: NSPredicate(format: "address == %@", account.address))
        if case .core(let account) = result {
            return account
        }
        
        let coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: context)
        coreAccount.address = account.address
        coreAccount.publicKey = account.publicKey
        
        let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
        chatroom.updatedAt = NSDate()
        
        coreAccount.chatroom = chatroom
        
        if let acc = knownContacts[account.address] {
            coreAccount.name = acc.name
            coreAccount.avatar = acc.avatar
            coreAccount.isSystem = acc.isSystem
            coreAccount.publicKey = acc.publicKey
            chatroom.isReadonly = acc.isReadonly
            chatroom.isHidden = acc.isHidden
            chatroom.title = acc.name
        }
        
        if let address = coreAccount.address,
            let name = addressBookService.getName(for: address) {
            coreAccount.name = name
            chatroom.title = name.checkAndReplaceSystemWallets()
        }
        
        return coreAccount
    }
    
    private func createCoreDataAccount(
        with address: String,
        publicKey: String,
        context: NSManagedObjectContext
    ) -> CoreDataAccount {
        let coreAccount = CoreDataAccount(entity: CoreDataAccount.entity(), insertInto: context)
        coreAccount.address = address
        coreAccount.publicKey = publicKey
        
        let chatroom = Chatroom(entity: Chatroom.entity(), insertInto: context)
        chatroom.updatedAt = NSDate()
        
        coreAccount.chatroom = chatroom
        
        if let acc = knownContacts[address] {
            coreAccount.name = acc.name
            coreAccount.avatar = acc.avatar
            coreAccount.isSystem = acc.isSystem
            if !acc.isSystem {
                coreAccount.publicKey = acc.publicKey
            }
            chatroom.isReadonly = acc.isReadonly
            chatroom.title = acc.name
        }
        
        return coreAccount
    }
}

// MARK: - Dummy
extension AdamantAccountsProvider {
    
    func getDummyAccount(for address: String) async throws -> DummyAccount {
        let validation = AdamantUtilities.validateAdamantAddress(address: address)
        if validation == .invalid {
            throw AccountsProviderDummyAccountError.invalidAddress(address: address)
        }
        
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = stack.container.viewContext
        
        switch await self.getAccount(byPredicate: NSPredicate(format: "address == %@", address)) {
        case .core(let account):
            throw AccountsProviderDummyAccountError.foundRealAccount(account)
            
        case .dummy(let account):
            return account
            
        case .notFound:
            let dummy = DummyAccount(entity: DummyAccount.entity(), insertInto: context)
            dummy.address = address
            
            do {
                try context.save()
                return dummy
            } catch {
                throw AccountsProviderDummyAccountError.internalError(error)
            }
        }
    }
}
