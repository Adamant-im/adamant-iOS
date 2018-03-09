//
//  Keypair.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct Keypair: Equatable {
	let publicKey: String
	let privateKey: String
	
	static func ==(lhs: Keypair, rhs: Keypair) -> Bool {
		return lhs.publicKey == rhs.publicKey && lhs.privateKey == rhs.privateKey
	}
}
