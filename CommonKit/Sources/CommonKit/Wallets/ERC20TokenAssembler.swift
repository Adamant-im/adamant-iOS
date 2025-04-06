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
        return erc20Tokens.map { _, info in
            erc20TokenWith(coinInfo: info)
        }
    }

    private static func erc20TokenWith(coinInfo info: CoinInfoDTO) -> ERC20Token {
        ERC20Token(
            symbol: info.symbol,
            name: info.name,
            contractAddress: info.contractId ?? "",
            decimals: info.decimals,
            naturalUnits: info.decimals,
            defaultVisibility: info.defaultVisibility ?? false,
            defaultOrdinalLevel: info.defaultOrdinalLevel,
            reliabilityGasPricePercent: info.reliabilityGasPricePercent ?? .zero,
            reliabilityGasLimitPercent: info.reliabilityGasLimitPercent ?? .zero,
            increasedGasPricePercent: Decimal(info.increasedGasPricePercent ?? .zero),
            defaultGasPriceGwei: info.defaultGasPriceGwei ?? .zero,
            defaultGasLimit: info.defaultGasLimit ?? .zero,
            warningGasPriceGwei: info.warningGasPriceGwei ?? .zero,
            transferDecimals: info.cryptoTransferDecimals
        )
    }
}
