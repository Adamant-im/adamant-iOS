//
//  SecuredStore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct StoreKey {
	private init() {}
}

protocol SecuredStore: class {
	func get(_ key: String) -> String?
	func set(_ value: String, for key: String)
	func remove(_ key: String)
    
    /// Remove everything
    func purgeStore()
}
