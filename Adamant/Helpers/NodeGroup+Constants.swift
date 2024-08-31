//
//  NodeGroup+Constants.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 27.12.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//
import Foundation
import CommonKit

extension NodeGroup {
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
        case .ipfs:
            return IPFSApiService.healthCheckParameters.onScreenUpdateInterval
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
        case .ipfs:
            return IPFSApiService.healthCheckParameters.crucialUpdateInterval
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
        case .ipfs:
            return IPFSApiService.healthCheckParameters.threshold
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
        case .ipfs:
            return IPFSApiService.healthCheckParameters.normalUpdateInterval
        }
    }
    
    // swiftlint:disable switch_case_alignment
    var minNodeVersion: Version? {
        guard let version = switch self {
        case .adm:
            AdmWalletService.minNodeVersion
        case .btc:
            BtcWalletService.minNodeVersion
        case .eth:
            EthWalletService.minNodeVersion
        case .klyNode:
            KlyWalletService.minNodeVersion
        case .klyService:
            KlyWalletService.minNodeVersion
        case .doge:
            DogeWalletService.minNodeVersion
        case .dash:
            DashWalletService.minNodeVersion
        case .ipfs:
            nil
        } else { return nil }
        
        return .init(version)
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
        case .ipfs:
            return IPFSApiService.symbol
        }
    }
    
    var blockchainHealthCheckParams: BlockchainHealthCheckParams {
        .init(
            group: self,
            name: name,
            normalUpdateInterval: normalUpdateInterval,
            crucialUpdateInterval: crucialUpdateInterval,
            minNodeVersion: minNodeVersion,
            nodeHeightEpsilon: nodeHeightEpsilon
        )
    }
}
