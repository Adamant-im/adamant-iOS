//
//  CoinInfoProvider.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 13.1.25..
//
import Foundation

public enum CoinInfoProvider {
    public static var coins: [String: CoinInfoDTO] {
        return cachedCoinInfo
    }

    private static var cachedCoinInfo: [String: CoinInfoDTO] = {
        let jsonDataArray = AssetLoader.loadFilesFromGeneral()
        var decodedData = [String: CoinInfoDTO]()
        
        let decoder = JSONDecoder()
        for data in jsonDataArray {
            do {
                let coinInfo = try decoder.decode(CoinInfoDTO.self, from: data)
                decodedData[coinInfo.symbol] = coinInfo
            } catch {
                print("Failed to decode CoinInfoDTO: \(error)")
            }
        }
        return decodedData
    }()
}
