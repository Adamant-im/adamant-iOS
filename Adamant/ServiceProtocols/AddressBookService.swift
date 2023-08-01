//
//  AddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

// MARK: - Notifications

extension Notification.Name {
    struct AdamantAddressBookService {
        /// Raised when user rename accounts in chat
        static let addressBookUpdated = Notification.Name("adamant.addressBookService.updated")
        
        private init() {}
    }
}

enum AddressBookChange {
    case newName(address: String, name: String)
    case updated(address: String, name: String)
    case removed(address: String)
}

extension AdamantUserInfoKey {
    struct AddressBook {
        
        /// Array of AddressBookChangeType
        static let changes = "adamant.addressBook.changes"
        
        private init() {}
    }
}

// MARK: - Result and Errors

enum AddressBookServiceResult {
    case success
    case failure(AddressBookServiceError)
}

enum AddressBookServiceError {
    case notLogged
    case notEnoughMoney
    case apiServiceError(error: ApiServiceError)
    case internalError(message: String, error: Error?)
}

extension AddressBookServiceError: RichError {
    var message: String {
        switch self {
        case .notLogged:
            return String.adamant.sharedErrors.userNotLogged
            
        case .notEnoughMoney:
            return .localized("AddressBookService.Error.notEnoughMoney", comment: "AddressBookService: Not enought money to save address into blockchain")
            
        case .apiServiceError(let error): return error.message
        case .internalError(let message, _): return message
        }
    }
    
    var internalError: Error? {
        switch self {
        case .notLogged, .notEnoughMoney: return nil
        case .apiServiceError(let error): return error.internalError
        case .internalError(_, let error): return error
        }
    }
    
    var level: ErrorLevel {
        switch self {
        case .notLogged, .notEnoughMoney: return .warning
        case .apiServiceError(let error): return error.level
        case .internalError: return .internalError
        }
    }
}

// MARK: -
protocol AddressBookService: AnyObject {
    // MARK: Work with Address book
    func set(name: String, for: String) async
    @MainActor func getName(for key: String) -> String?
    
    // MARK: Updating & saving
    func update() async -> AddressBookServiceResult? 
    
    var hasChanges: Bool { get }
    func saveIfNeeded() async
}
