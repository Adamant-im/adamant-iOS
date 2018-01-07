//
//  AdamantError.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 06.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
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

