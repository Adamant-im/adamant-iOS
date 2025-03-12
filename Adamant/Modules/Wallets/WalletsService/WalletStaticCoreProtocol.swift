//
//  WalletStaticCoreProtocol.swift
//  Adamant
//
//  Created by Владимир Клевцов on 17.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import Foundation
import BigInt
import CommonKit
import UIKit
import AdamantWalletsKit

protocol WalletStaticCoreProtocol {
    static var currencySymbol: String { get }
    static var currencyLogo: UIImage { get }
    static var qqPrefix: String { get }
}
extension WalletStaticCoreProtocol {
    static var coinInfo: CoinInfoDTO? {
        CoinInfoProvider.coins[currencySymbol]
    }
    
    static var fixedFee: Decimal {
        coinInfo?.fixedFee ?? coinInfo?.defaultFee ?? 0.0
    }
    
    static var currencyExponent: Int {
        -(coinInfo?.decimals ?? 0)
    }
    
    static var qqPrefix: String {
        coinInfo?.qqPrefix ?? ""
    }
    static var healthCheckParameters: CoinHealthCheckParameters {
        let coinInfoNH = coinInfo?.nodes?.healthCheck
        let coinInfoSIH = coinInfo?.services?.infoService?.healthCheck
        let coinInfoSNH = coinInfo?.services?.ipfsNode?.healthCheck
        
        return CoinHealthCheckParameters(
            normalUpdateInterval: TimeInterval(coinInfoNH?.normalUpdateInterval ?? 0 / 1000),
            crucialUpdateInterval: TimeInterval(coinInfoNH?.crucialUpdateInterval ?? 0 / 1000),
            onScreenUpdateInterval: TimeInterval(coinInfoNH?.onScreenUpdateInterval ?? 0 / 1000),
            
            threshold: coinInfoNH?.threshold ?? 0,
            
            normalServiceUpdateInterval: TimeInterval(coinInfoSIH?.normalUpdateInterval ?? coinInfoSNH?.normalUpdateInterval ?? 0),
            crucialServiceUpdateInterval: TimeInterval(coinInfoSIH?.crucialUpdateInterval ?? coinInfoSNH?.crucialUpdateInterval ?? 0),
            onScreenServiceUpdateInterval: TimeInterval(coinInfoSIH?.onScreenUpdateInterval ?? coinInfoSNH?.onScreenUpdateInterval ?? 0))
    }
    static var newPendingInterval: Int {
        coinInfo?.txFetchInfo?.newPendingInterval ?? 0
    }
    
    static var oldPendingInterval: Int {
        coinInfo?.txFetchInfo?.oldPendingInterval ?? 0
    }
    
    static var registeredInterval: Int {
        coinInfo?.txFetchInfo?.registeredInterval ?? 0
    }
    
    static var newPendingAttempts: Int {
        coinInfo?.txFetchInfo?.newPendingAttempts ?? 0
    }
    
    static var oldPendingAttempts: Int {
        coinInfo?.txFetchInfo?.oldPendingAttempts ?? 0
    }
    
    var tokenName: String {
        Self.coinInfo?.name ?? ""
    }
    
    var consistencyMaxTime: Double {
        Double(Self.coinInfo?.txFetchInfo?.newPendingInterval ?? 0) / 1000.0
    }
    
    var minBalance: Decimal {
        Self.coinInfo?.minBalance ?? 0.0
    }
    
    var minAmount: Decimal {
        Decimal(Self.coinInfo?.minTransferAmount ?? 0.0)
    }
    
    var defaultVisibility: Bool {
        Self.coinInfo?.defaultVisibility ?? false
    }
    
    var defaultOrdinalLevel: Int? {
        Self.coinInfo?.defaultOrdinalLevel
    }
    
    static var minNodeVersion: String? {
        coinInfo?.nodes?.minVersion
    }
    
    var transferDecimals: Int {
        Self.coinInfo?.cryptoTransferDecimals ?? 0
    }
    
    static var explorerAddress: String {
        coinInfo?.explorerAddress ?? ""
    }
    static var explorerTx: String {
        coinInfo?.explorer ?? ""
    }
    
    static var nodes: [Node] {
        coinInfo?.nodes?.list.map { walletNode in
            Node.makeDefaultNode(
                url: URL(string: walletNode.url)!,
                altUrl: walletNode.altIP.flatMap { URL(string: $0) }
            )
        } ?? []
    }
    
    static var serviceNodes: [Node] {
        coinInfo?.services?.infoService?.list.map { serviceNode in
            Node.makeDefaultNode(
                url: URL(string: serviceNode.url)!,
                altUrl: serviceNode.altIP.flatMap { URL(string: $0) }
            )
        } ?? []
    }
}
