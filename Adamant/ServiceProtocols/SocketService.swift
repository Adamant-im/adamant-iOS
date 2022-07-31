//
//  SocketService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

// - MARK: SocketService

protocol SocketService: AnyObject {
    func connect(address: String, handler: @escaping (ApiServiceResult<Transaction>) -> Void)
    func disconnect()
}
