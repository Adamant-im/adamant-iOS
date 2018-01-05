//
//  Error.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 05.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation

struct AdamantCoreError: Error {
	let message: String
	let internalError: Error?
	
	init(message: String) {
		self.message = message
		self.internalError = nil
	}
	
	init(message: String, error: Error) {
		self.message = message
		self.internalError = error
	}
}

extension AdamantCoreError: CustomStringConvertible {
	public var description: String {
		return message
	}
}
