//
//  AdamantHash.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantHash {
	public let bytes: [UInt8]
	public let hex: String
	
	init(bytes: [UInt8]) {
		self.bytes = bytes
		
		if bytes.count > 0 {
			self.hex = Data(bytes: bytes).reduce("") {$0 + String(format: "%02x", $1)}
		} else {
			self.hex = ""
		}
	}
	
	init(hex: String) {
		self.bytes = [] // TODO: 
		self.hex = hex
	}
}
