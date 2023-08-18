//
//  ReachabilityMonitor.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Notification.Name {
    struct AdamantReachabilityMonitor {
        static let reachabilityChanged = Notification.Name("adamant.reachabilityMonitor.reachabilityChanged")
        
        private init() {}
    }
}

extension AdamantUserInfoKey {
    struct ReachabilityMonitor {
        /// Contains Connection object
        static let connection = "adamant.reachability.connection"
        
        private init() {}
    }
}

protocol ReachabilityMonitor {
    var connection: Bool { get }
    
    func start()
    func stop()
    
    func performWhenConnectionEstablished(_ request: @Sendable @escaping () -> Void)
}
