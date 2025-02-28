//
//  ERC20GasAlgorithm.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 28.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import BigInt

protocol ERC20GasAlgorithmComputable {
    var reliabilityGasPricePercent: BigUInt { get }
    var reliabilityGasLimitPercent: BigUInt { get }
    var increasedGasPricePercent: Decimal { get }
}

extension ERC20GasAlgorithmComputable {
    func updateGasAndFee(
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        gasPriceCoeficient: Decimal,
        completion: @escaping (_ gasPrice: BigUInt, _ gasLimit: BigUInt, _ newFee: Decimal) -> Void
    ) {
        let reliabilityGasPricePercent = gasPrice / reliabilityGasPricePercent
        let reliabilityGasLimitPercent = gasLimit / reliabilityGasLimitPercent

        let reliableGasPrice = reliabilityGasPricePercent + gasPrice
        let reliableGasLimit = reliabilityGasLimitPercent + gasLimit
        
        let finalGasPrice = BigUInt(reliableGasPrice.asDouble() * gasPriceCoeficient.doubleValue)
        let newFee = (finalGasPrice * reliableGasLimit).asDecimal(exponent: EthWalletService.currencyExponent)
        
        completion(
            finalGasPrice,
            reliableGasLimit,
            newFee
        )
    }
}
