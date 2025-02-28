//
//  ERC20ApiWalletService+GasAlgorithm.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 27.02.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import BigInt
import Foundation

// MARK: - Fee updates
extension ERC20WalletService {
    func updateGasAndFee(
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        gasPriceCoeficient: Decimal,
        completion: @escaping (_ gasPrice: BigUInt, _ gasLimit: BigUInt, _ newFee: Decimal) -> Void
    ) {
        let reliabilityGasPricePercentage = BigUInt(token.reliabilityGasPricePercent)
        let reliabilityGasLimitPercentage = BigUInt(token.reliabilityGasLimitPercent)
        
        let reliabilityGasPricePercent = gasPrice / reliabilityGasPricePercentage
        let reliabilityGasLimitPercent = gasLimit / reliabilityGasLimitPercentage
        let reliableGasPrice = reliabilityGasPricePercent + gasPrice
        let reliableGasLimit = reliabilityGasLimitPercent + gasLimit
        
        completion(
            BigUInt(reliableGasPrice.asDouble() * gasPriceCoeficient.doubleValue),
            reliableGasLimit,
            (reliableGasPrice * reliableGasLimit).asDecimal(exponent: EthWalletService.currencyExponent) * gasPriceCoeficient
        )
    }
}
