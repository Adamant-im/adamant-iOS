//
//  GlobalActorSerialExecutor.swift
//  CommonKit
//
//  Created by Andrew G on 20.10.2024.
//

import Foundation

public final class GlobalActorSerialExecutor: SerialExecutor {
    private let queue = DispatchQueue(label: .init(describing: GlobalActorSerialExecutor.self))
    
    public func enqueue(_ job: UnownedJob) {
        queue.async { [self] in
            job.runSynchronously(on: asUnownedSerialExecutor())
        }
    }
    
    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        .init(ordinary: self)
    }
    
    public init() {}
}
