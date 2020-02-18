//
//  AdamantReachability.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Reachability

// MAKR: - Convinients
extension Reachability.Connection {
    var adamantConnection: AdamantConnection {
        switch self {
        case .none:
            return .none
        
        case .wifi:
            return .wifi
            
        case .cellular:
            return .cellular
        }
    }
}

// MARK: - AdamantReachability wrapper
class AdamantReachability: ReachabilityMonitor {
    let reachability: Reachability
    
    private(set) var isActive = false
    
    var connection: AdamantConnection {
        return reachability.connection.adamantConnection
    }
    
    init() {
        reachability = Reachability()!
        reachability.whenReachable = { [weak self] reachability in
            let userInfo: [String:Any] = [AdamantUserInfoKey.ReachabilityMonitor.connection:reachability.connection.adamantConnection]
            NotificationCenter.default.post(name: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: self, userInfo: userInfo)
        }
        
        reachability.whenUnreachable = { [weak self] reachability in
            let userInfo: [String:Any] = [AdamantUserInfoKey.ReachabilityMonitor.connection:reachability.connection.adamantConnection]
            NotificationCenter.default.post(name: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: self, userInfo: userInfo)
        }
    }
    
    deinit {
        stop()
    }

    func start() {
        guard !isActive else {
            return
        }
        
        do {
            try reachability.startNotifier()
            isActive = true
        } catch {
            isActive = false
        }
    }

    func stop() {
        guard isActive else {
            return
        }

        NotificationCenter.default.removeObserver(self)
        reachability.stopNotifier()
        isActive = false
    }
}
