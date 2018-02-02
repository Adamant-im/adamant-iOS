//
//  DataProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum Status {
	case empty
	case updating
	case upToDate
	case failedToUpdate(Error)
}

protocol DataProvider {
	var status: Status { get }
	
	func reload()
	func update()
	func reset()
}


// MARK: - Status Equatable
extension Status: Equatable {
	
	/// Simple equatable function. Does not checks associated values.
	static func ==(lhs: Status, rhs: Status) -> Bool {
		switch (lhs, rhs) {
		case (.empty, .empty): return true
		case (.updating, .updating): return true
		case (.upToDate, .upToDate): return true
		
		case (.failedToUpdate(_), .failedToUpdate(_)): return true
			
		default: return false
		}
	}
}
