//
//  HealthCheckActor.swift
//  CommonKit
//
//  Created by Andrew G on 20.10.2024.
//

import Foundation

@globalActor
public actor HealthCheckActor: GlobalActor {
    private static let executor = GlobalActorSerialExecutor(HealthCheckActor.self)
    
    public static let shared = HealthCheckActor()
    public static let sharedUnownedExecutor = HealthCheckActor.executor.asUnownedSerialExecutor()
    
    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.sharedUnownedExecutor
    }
}
