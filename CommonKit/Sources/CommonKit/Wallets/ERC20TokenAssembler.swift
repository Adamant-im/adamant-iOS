//
//  ERC20TokenComparer.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 17.1.25..
//
import AdamantWalletsKit
import Foundation

public enum ERC20TokenAssembly {
    public static func getERC20Tokens(tokensStorage: AnyTokensStorage) -> [ERC20Token] {
        guard let erc20Tokens = tokensStorage[.declared(.ethereum)] else { return [] }
        return erc20Tokens.map { symbol, info in
                .init(
                    symbol: info.symbol,
                    name: info.name,
                    contractAddress: info.contractId ?? "",
                    decimals: info.decimals,
                    naturalUnits: info.decimals,
                    defaultVisibility: info.defaultVisibility ?? false,
                    defaultOrdinalLevel: info.defaultOrdinalLevel,
                    reliabilityGasPricePercent: info.reliabilityGasPricePercent ?? .zero,
                    reliabilityGasLimitPercent: info.reliabilityGasLimitPercent ?? .zero,
                    defaultGasPriceGwei: info.defaultGasPriceGwei ?? .zero,
                    defaultGasLimit: info.defaultGasLimit ?? .zero,
                    warningGasPriceGwei: info.warningGasPriceGwei ?? .zero,
                    transferDecimals: info.cryptoTransferDecimals
                )
        }
    }
}
