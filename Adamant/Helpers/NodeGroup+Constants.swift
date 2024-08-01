//
//  NodeGroup+Constants.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.12.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//
import Foundation
import CommonKit

public extension NodeGroup {
    var onScreenUpdateInterval: TimeInterval {
        switch self {
        case .adm:
            return AdmWalletService.healthCheckParameters.onScreenUpdateInterval
        case .btc:
            return BtcWalletService.healthCheckParameters.onScreenUpdateInterval
        case .eth:
            return EthWalletService.healthCheckParameters.onScreenUpdateInterval
        case .klyNode:
            return KlyWalletService.healthCheckParameters.onScreenUpdateInterval
        case .klyService:
            return KlyWalletService.healthCheckParameters.onScreenServiceUpdateInterval
        case .doge:
            return DogeWalletService.healthCheckParameters.onScreenUpdateInterval
        case .dash:
            return DashWalletService.healthCheckParameters.onScreenUpdateInterval
        }
    }

    var crucialUpdateInterval: TimeInterval {
        switch self {
        case .adm:
            return AdmWalletService.healthCheckParameters.crucialUpdateInterval
        case .btc:
            return BtcWalletService.healthCheckParameters.crucialUpdateInterval
        case .eth:
            return EthWalletService.healthCheckParameters.crucialUpdateInterval
        case .klyNode:
            return KlyWalletService.healthCheckParameters.crucialUpdateInterval
        case .klyService:
            return KlyWalletService.healthCheckParameters.crucialServiceUpdateInterval
        case .doge:
            return DogeWalletService.healthCheckParameters.crucialUpdateInterval
        case .dash:
            return DashWalletService.healthCheckParameters.crucialUpdateInterval
        }
    }

    var nodeHeightEpsilon: Int {
        switch self {
        case .adm:
            return AdmWalletService.healthCheckParameters.threshold
        case .btc:
            return BtcWalletService.healthCheckParameters.threshold
        case .eth:
            return EthWalletService.healthCheckParameters.threshold
        case .klyNode:
            return KlyWalletService.healthCheckParameters.threshold
        case .klyService:
            return KlyWalletService.healthCheckParameters.threshold
        case .doge:
            return DogeWalletService.healthCheckParameters.threshold
        case .dash:
            return DashWalletService.healthCheckParameters.threshold
        }
    }

    var normalUpdateInterval: TimeInterval {
        switch self {
        case .adm:
            return AdmWalletService.healthCheckParameters.normalUpdateInterval
        case .btc:
            return BtcWalletService.healthCheckParameters.normalUpdateInterval
        case .eth:
            return EthWalletService.healthCheckParameters.normalUpdateInterval
        case .klyNode:
            return KlyWalletService.healthCheckParameters.normalUpdateInterval
        case .klyService:
            return KlyWalletService.healthCheckParameters.normalServiceUpdateInterval
        case .doge:
            return DogeWalletService.healthCheckParameters.normalUpdateInterval
        case .dash:
            return DashWalletService.healthCheckParameters.normalUpdateInterval
        }
    }
    
    var minNodeVersion: Double {
        var minNodeVersion: String?
        switch self {
        case .adm:
            minNodeVersion = AdmWalletService.minNodeVersion
        case .btc:
            minNodeVersion = BtcWalletService.minNodeVersion
        case .eth:
            minNodeVersion = EthWalletService.minNodeVersion
        case .klyNode:
            minNodeVersion = KlyWalletService.minNodeVersion
        case .klyService:
            minNodeVersion = KlyWalletService.minNodeVersion
        case .doge:
            minNodeVersion = DogeWalletService.minNodeVersion
        case .dash:
            minNodeVersion = DashWalletService.minNodeVersion
        }
        
        guard let versionNumber = Node.stringToDouble(minNodeVersion) else {
            return .zero
        }
        
        return versionNumber
    }
    
    var name: String {
        switch self {
        case .btc:
            return BtcWalletService.tokenNetworkSymbol
        case .eth:
            return EthWalletService.tokenNetworkSymbol
        case .klyNode:
            return KlyWalletService.tokenNetworkSymbol
        case .klyService:
            return KlyWalletService.tokenNetworkSymbol
            + " " + .adamant.coinsNodesList.serviceNode
        case .doge:
            return DogeWalletService.tokenNetworkSymbol
        case .dash:
            return DashWalletService.tokenNetworkSymbol
        case .adm:
            return AdmWalletService.tokenNetworkSymbol
        }
    }
    
    var includeVersionTitle: Bool {
        switch self {
        case .btc, .klyNode, .klyService, .doge, .adm:
            return true
        case .eth, .dash:
            return false
        }
    }
}
