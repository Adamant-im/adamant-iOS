//
//  AddressBookService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 24/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

// MARK: - Notifications

extension Notification.Name {
	struct AdamantAddressBookService {
		/// Raised when user rename accounts in chat
		static let updated = Notification.Name("adamant.addressBookService.updated")
		
		private init() {}
	}
}


// MARK: -
protocol AddressBookService: class {
    
    var addressBook: [String:String] { get }
    
    func getAddressBook(completion: @escaping (ApiServiceResult<[String:String]>) -> Void)
    
    func set(name: String, for: String)
    
    func saveIfNeeded()

}
