//
//  WalletConfig.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 4.1.25..
//
import Foundation


struct WalletConfigManager {
    
    public static var supportedTokens: [ERC20Token] {
        cachedWalletConfigs
    }
}
