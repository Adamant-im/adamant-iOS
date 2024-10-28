//
//  AdamantReachability.swift
//  Adamant
//
//  Created by Anokhov Pavel on 20.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import Reachability
import Network
import CommonKit

// MARK: - AdamantReachability wrapper
final class AdamantReachability: ReachabilityMonitor, @unchecked Sendable {
    @ObservableValue private(set) var connection = true
    
    private let monitor = NWPathMonitor()
    
    var connectionPublisher: AnyObservable<Bool> {
        $connection.eraseToAnyPublisher()
    }
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] _ in
            guard let self = self else { return }
            self.updateConnection()
            
            let userInfo: [String: Any] = [
                AdamantUserInfoKey.ReachabilityMonitor.connection: self.connection
            ]
            
            NotificationCenter.default.post(
                name: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged,
                object: self,
                userInfo: userInfo
            )
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
    
    private func updateConnection() {
        switch monitor.currentPath.status {
        case .satisfied:
            connection = true
        case .unsatisfied, .requiresConnection:
            connection = false
        @unknown default:
            connection = false
        }
    }
}
