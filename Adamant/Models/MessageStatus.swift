//
//  MessageStatus.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public enum MessageStatus: Int16, Codable {
    case pending = 0
    case delivered = 1
    case failed = 2
}
