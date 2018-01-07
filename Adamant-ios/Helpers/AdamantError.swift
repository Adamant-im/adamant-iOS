//
//  AdamantError.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantError: Error {
	public let message: String
	public let internalError: Error?
	
	init(message: String, error: Error? = nil) {
		self.message = message
		self.internalError = error
	}
}

extension AdamantError: CustomStringConvertible {
	public var description: String {
		return message
	}
}

