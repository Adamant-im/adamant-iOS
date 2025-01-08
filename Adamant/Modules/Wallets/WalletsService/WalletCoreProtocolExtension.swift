//
//  WalletCoreProtocolExtension.swift
//  Adamant
//
//  Created by Владимир Клевцов on 8.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import Foundation
import BigInt
import CommonKit

extension WalletCoreProtocol {
    static var coinInfo: CoinInfoDTO? {
        CoinInfoDTO.coins[currencySymbol]
    }
    
    static var fixedFee: Decimal {
        coinInfo?.fixedFee ?? 0.0
    }
    
    static var currencyExponent: Int {
        coinInfo?.decimals ?? 0
    }
    
    static var qqPrefix: String {
        coinInfo?.qqPrefix ?? ""
    }
    static var healthCheckParameters: CoinHealthCheckParameters { CoinHealthCheckParameters(
        normalUpdateInterval: TimeInterval(coinInfo?.nodes?.healthCheck.normalUpdateInterval ?? 0 / 1000),
        crucialUpdateInterval: TimeInterval(coinInfo?.nodes?.healthCheck.crucialUpdateInterval ?? 0 / 1000),
        onScreenUpdateInterval: TimeInterval(coinInfo?.nodes?.healthCheck.onScreenUpdateInterval ?? 0 / 1000),
        threshold: coinInfo?.nodes?.healthCheck.threshold ?? 0,
        normalServiceUpdateInterval: 330,
        crucialServiceUpdateInterval: 30,
        onScreenServiceUpdateInterval: 10
    )
    }
    var tokenName: String {
        Self.coinInfo?.name ?? ""
    }
    
    var consistencyMaxTime: Double {
        Double(Self.coinInfo?.txFetchInfo?.newPendingInterval ?? 0)
    }
    
    var minBalance: Decimal {
        Self.coinInfo?.defaultFee ?? 0.0
    }
    
    var minAmount: Decimal {
        Self.coinInfo?.fixedFee ?? 0.0
    }
    
    var defaultVisibility: Bool {
        Self.coinInfo?.defaultVisibility ?? false
    }
    
    var defaultOrdinalLevel: Int? {
        Self.coinInfo?.defaultOrdinalLevel
    }
    
    var transferDecimals: Int {
        Self.coinInfo?.cryptoTransferDecimals ?? 0
    }
    
    static var explorerAddress: String {
        coinInfo?.explorer ?? ""
    }
}
