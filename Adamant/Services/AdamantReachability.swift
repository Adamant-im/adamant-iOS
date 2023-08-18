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

// MARK: - AdamantReachability wrapper
final class AdamantReachability: ReachabilityMonitor {
    typealias NetworkRequest = @Sendable () -> Void
    
    private let monitor = NWPathMonitor()
    private(set) var connection = true
    private(set) var processedRequests = [NetworkRequest]()
    
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
    
    func performWhenConnectionEstablished(_ request: @escaping NetworkRequest) {
        guard !connection else { return request() }
        processedRequests.append(request)
    }
    
    private func updateConnection() {
        switch monitor.currentPath.status {
        case .satisfied:
            connection = true
            processRequests()
        case .unsatisfied, .requiresConnection:
            connection = false
        @unknown default:
            connection = false
        }
    }
    
    private func processRequests() {
        processedRequests.forEach { $0() }
        processedRequests = []
    }
}
