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
    
    /// Default is async queue with .utilities priority.
    var defaultResponseDispatchQueue: DispatchQueue { get }
    
    // MARK: - Connection
    
    func connect(address: String)
    
    func disconnect()
    
    // MARK: - Receive New Transaction
    
    func receiveNewTransaction(completion: ((ApiServiceResult<Transaction>) -> Void)?)
}
