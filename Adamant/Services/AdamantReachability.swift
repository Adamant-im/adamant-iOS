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

// MAKR: - Convinients
extension Reachability.Connection {
    var adamantConnection: AdamantConnection {
        switch self {
        case .none, .unavailable:
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
    let monitorForWifi = NWPathMonitor(requiredInterfaceType: .wifi)
    let monitorForCellular = NWPathMonitor(requiredInterfaceType: .cellular)
    private var wifiStatus: NWPath.Status = .satisfied
    private var cellularStatus: NWPath.Status = .satisfied

    var connection: AdamantConnection {
        if wifiStatus == .satisfied     { return AdamantConnection.wifi     }
        if cellularStatus == .satisfied { return AdamantConnection.cellular }
        return AdamantConnection.none
    }
    
    func start() {
        monitorForWifi.pathUpdateHandler = { [weak self] path in
            self?.wifiStatus = path.status
            let status = path.status == .satisfied ? AdamantConnection.wifi : AdamantConnection.none
            let userInfo: [String:Any] = [AdamantUserInfoKey.ReachabilityMonitor.connection: status]
            NotificationCenter.default.post(name: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: self, userInfo: userInfo)
        }
        monitorForCellular.pathUpdateHandler = { [weak self] path in
            self?.cellularStatus = path.status
            let status = path.status == .satisfied ? AdamantConnection.cellular : AdamantConnection.none
            let userInfo: [String:Any] = [AdamantUserInfoKey.ReachabilityMonitor.connection: status]
            NotificationCenter.default.post(name: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: self, userInfo: userInfo)
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitorForCellular.start(queue: queue)
        monitorForWifi.start(queue: queue)
    }

    func stop() {
        monitorForWifi.cancel()
        monitorForCellular.cancel()
    }
    
}
