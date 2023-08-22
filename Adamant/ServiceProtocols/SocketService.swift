//
//  SocketService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 19.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

// MARK: - Notifications

extension Notification.Name {
    enum SocketService {
        static let currentNodeUpdate = Notification.Name("adamant.socketService.currentNodeUpdate")
    }
}

// - MARK: SocketService

protocol SocketService: AnyObject {
    var currentNode: Node? { get }
    
    func connect(address: String, handler: @escaping (ApiServiceResult<Transaction>) -> Void)
    func disconnect()
}
