//
//  TransactionType.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

enum TransactionType: Int, Codable {
	case send = 0
	case signature
	case delegate
	case vote
	case multi
	case dapp
	case inTransfer
	case outTransfer
	case chatMessage
}
