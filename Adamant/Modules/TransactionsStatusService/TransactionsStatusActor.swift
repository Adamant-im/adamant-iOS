//
//  TransactionsStatusActor.swift
//  Adamant
//
//  Created by Andrew G on 20.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation
import CommonKit

@globalActor
actor TransactionsStatusActor: GlobalActor {
    private static let executor = GlobalActorSerialExecutor(TransactionsStatusActor.self)
    
    static let shared = TransactionsStatusActor()
    static let sharedUnownedExecutor = TransactionsStatusActor.executor.asUnownedSerialExecutor()
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.sharedUnownedExecutor
    }
}
