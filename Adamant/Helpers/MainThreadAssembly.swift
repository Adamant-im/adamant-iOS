//
//  MainThreadAssembly.swift
//  Adamant
//
//  Created by Andrew G on 07.10.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Swinject
import CommonKit
import Foundation

@MainActor
protocol MainThreadAssembly: Assembly, Sendable {
    func assembleOnMainThread(container: Container)
}

extension MainThreadAssembly {
    nonisolated func assemble(container: Container) {
        let sendable = Atomic(container)
        
        MainActor.assumeIsolatedSafe {
            assembleOnMainThread(container: sendable.value)
        }
    }
}
