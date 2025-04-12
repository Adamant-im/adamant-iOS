import AdamantWalletsKit
//
//  SmartTokenInfoProtocol.swift
//  Adamant
//
//  Created by Владимир Клевцов on 17.1.25..
//  Copyright © 2025 Adamant. All rights reserved.
//
import BigInt
import CommonKit

extension EthWalletService {
    var reliabilityGasPricePercent: BigUInt {
        BigUInt(Self.coinInfo?.reliabilityGasLimitPercent ?? 10)
    }

    var reliabilityGasLimitPercent: BigUInt {
        BigUInt(Self.coinInfo?.reliabilityGasLimitPercent ?? 10)
    }

    var defaultGasPriceGwei: BigUInt {
        BigUInt(Self.coinInfo?.defaultGasPriceGwei ?? 10)
    }

    var defaultGasLimit: BigUInt {
        BigUInt(Self.coinInfo?.defaultGasLimit ?? 22000)
    }

    var warningGasPriceGwei: BigUInt {
        BigUInt(Self.coinInfo?.warningGasPriceGwei ?? 25)
    }
}
