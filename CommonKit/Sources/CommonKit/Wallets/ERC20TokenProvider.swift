//
//  ERC20TokenProvider.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 13.1.25..
//
enum ERC20TokenComparer {
   static func loadTokens() -> [ERC20Token] {
        let allCoins = CoinInfoProvider.coins
        let allAssets = BlockchainInfoProvider.assets
        
        return mapTokens(allAssets: allAssets, allCoins: allCoins)
    }
    
    private static func mapTokens(allAssets: [BlockchainAssetsDTO], allCoins: [String: CoinInfoDTO]) -> [ERC20Token] {
        allAssets.flatMap { asset in
            asset.childBlockchains.compactMap { _, childBlockchain in
                guard let coinInfo = allCoins[childBlockchain.symbol] else {
                    return nil
                }
                
                let defaultVisibility = childBlockchain.defaultVisibility ?? coinInfo.defaultVisibility ?? false
                let defaultOrdinalLevel = childBlockchain.defaultOrdinalLevel ?? coinInfo.defaultOrdinalLevel
                let reliabilityGasPricePercent = coinInfo.reliabilityGasPricePercent ?? 10
                let reliabilityGasLimitPercent = coinInfo.reliabilityGasLimitPercent ?? 10
                let defaultGasPriceGwei = coinInfo.defaultGasPriceGwei ?? 10
                let defaultGasLimit = asset.mainInfo.defaultGasLimit
                let warningGasPriceGwei = coinInfo.warningGasPriceGwei ?? 25
                
                return ERC20Token(
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
            }
        }
    }
}
