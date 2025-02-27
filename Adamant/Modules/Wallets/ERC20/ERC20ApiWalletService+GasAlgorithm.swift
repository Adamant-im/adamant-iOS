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
    func getNewFee(
        gasPrice: BigUInt,
        gasLimit: BigUInt,
        feeCoeficient: Decimal,
        completion: @escaping (_ gasPrice: BigUInt, _ gasLimit: BigUInt, _ newFee: Decimal) -> Void
    ) {
        let reliabilityGasPricePercentage = BigUInt(token.reliabilityGasPricePercent)
        let reliabilityGasLimitPercentage = BigUInt(token.reliabilityGasLimitPercent)
        
        let reliabilityGasPricePercent = gasPrice / reliabilityGasPricePercentage
        let reliabilityGasLimitPercent = gasLimit / reliabilityGasLimitPercentage
        let finalGasPrice = reliabilityGasPricePercent + gasPrice
        let finalGasLimit = reliabilityGasLimitPercent + gasLimit
        
        completion(
            BigUInt(finalGasPrice.asDouble() * feeCoeficient.doubleValue),
            finalGasLimit,
            (finalGasPrice * finalGasLimit).asDecimal(exponent: EthWalletService.currencyExponent) * feeCoeficient
        )
    }
}
