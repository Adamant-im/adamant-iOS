//
//  CoinInfoProvider.swift
//  CommonKit
//
//  Created by Владимир Клевцов on 17.1.25..
//
import AdamantWalletsKit
import Foundation

public enum CoinInfoProvider {
    public static var coins: [String: CoinInfoDTO] {
        return cachedCoinInfo
    }

    private static var cachedCoinInfo: [String: CoinInfoDTO] = {
        let jsonDataArray = JsonLoader.loadFilesFromGeneral()
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
