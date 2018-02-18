//
//  ChatType.swift
//  Adamant
//
//  Created by Anokhov Pavel on 12.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

/// - messageExpensive: Old message type, with 0.005 transaction fee
/// - message: new and main message type, with 0.001 transaction fee
enum ChatType: Int, Codable {
	case messageOld = 0
	case message = 1
}
