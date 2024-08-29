//
//  MessageStatus.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public enum MessageStatus: Codable, Equatable {
    case pending
    case delivered
    case failed(String?)
}
