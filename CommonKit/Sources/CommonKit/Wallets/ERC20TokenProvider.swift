//
//  ERC20TokenProvider.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 8.1.25..
//
struct ERC20TokenProvider {
    static func loadTokens() -> [ERC20Token] {
        var tokens = [ERC20Token]()
        
        let allCoins = CoinInfoDTO.coins
        
        let allAssets = BlockchainAssetsDTO.assets
        
        for asset in allAssets {
            for (_, childBlockchain) in asset.childBlockchains {
                if let coinInfo = allCoins[childBlockchain.symbol] {
                    let defaultVisibility = childBlockchain.defaultVisibility ?? coinInfo.defaultVisibility ?? false
                    let defaultOrdinalLevel = childBlockchain.defaultOrdinalLevel ?? coinInfo.defaultOrdinalLevel
                    let reliabilityGasPricePercent = coinInfo.txFetchInfo?.newPendingInterval ?? 10
                    let reliabilityGasLimitPercent = coinInfo.txFetchInfo?.oldPendingInterval ?? 10
                    let defaultGasPriceGwei = asset.mainInfo.defaultGasLimit
                    let defaultGasLimit = asset.mainInfo.defaultGasLimit
                    let warningGasPriceGwei = coinInfo.txFetchInfo?.newPendingInterval ?? 25
                    
                    let token = ERC20Token(
                        symbol: childBlockchain.symbol,
                        name: childBlockchain.name,
                        contractAddress: childBlockchain.contractId,
                        decimals: childBlockchain.decimals,
                        naturalUnits: childBlockchain.decimals,
                        defaultVisibility: defaultVisibility,
                        defaultOrdinalLevel: defaultOrdinalLevel,
                        reliabilityGasPricePercent: reliabilityGasPricePercent,
                        reliabilityGasLimitPercent: reliabilityGasLimitPercent,
                        defaultGasPriceGwei: defaultGasPriceGwei,
                        defaultGasLimit: defaultGasLimit,
                        warningGasPriceGwei: warningGasPriceGwei,
                        transferDecimals: coinInfo.cryptoTransferDecimals
                    )
                    tokens.append(token)
                }
            }
        }
        return tokens
    }
}
