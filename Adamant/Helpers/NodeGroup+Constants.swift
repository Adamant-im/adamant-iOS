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
        case .lskNode:
            return LskWalletService.healthCheckParameters.onScreenUpdateInterval
        case .lskService:
            return LskWalletService.healthCheckParameters.onScreenServiceUpdateInterval
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
        case .lskNode:
            return LskWalletService.healthCheckParameters.crucialUpdateInterval
        case .lskService:
            return LskWalletService.healthCheckParameters.crucialServiceUpdateInterval
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
        case .lskNode:
            return LskWalletService.healthCheckParameters.threshold
        case .lskService:
            return LskWalletService.healthCheckParameters.threshold
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
        case .lskNode:
            return LskWalletService.healthCheckParameters.normalUpdateInterval
        case .lskService:
            return LskWalletService.healthCheckParameters.normalServiceUpdateInterval
        case .doge:
            return DogeWalletService.healthCheckParameters.normalUpdateInterval
        case .dash:
            return DashWalletService.healthCheckParameters.normalUpdateInterval
        }
    }
}
