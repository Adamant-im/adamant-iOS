//
//  ERC20Token.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

public struct ERC20Token: Sendable {
    public let symbol: String
    public let name: String
    public let contractAddress: String
    public let decimals: Int
    public let naturalUnits: Int
    public let defaultVisibility: Bool
    public let defaultOrdinalLevel: Int?
    public let reliabilityGasPricePercent: Int
    public let reliabilityGasLimitPercent: Int
    public let defaultGasPriceGwei: Int
    public let defaultGasLimit: Int
    public let warningGasPriceGwei: Int
    public let transferDecimals: Int
    
    public var logo: UIImage {
        .asset(named: "\(symbol.lowercased())_wallet")
            ?? .asset(named: "ethereum_wallet")
            ?? UIImage()
    }
}
