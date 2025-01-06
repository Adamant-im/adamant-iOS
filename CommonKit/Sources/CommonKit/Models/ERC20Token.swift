//
//  ERC20Token.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

extension FileManager {
    func imageScale(named name: String, in directory: URL) -> UIImage? {
        let scale = Int(UIScreen.main.scale)
        let scaledFileNames = [
            "\(name)@\(scale)x.png",
            "\(name)@2x.png",
            "\(name)@3x.png",
            "\(name).png"
        ]

        for fileName in scaledFileNames {
            let fileURL = directory.appendingPathComponent(fileName)
            if fileExists(atPath: fileURL.path) {
                return UIImage(contentsOfFile: fileURL.path)
            }
        }

        return nil
    }
}
//public struct ERC20Token: Decodable, Sendable {
//    public let symbol: String
//    public let name: String
//    public let contractAddress: String
//    public let decimals: Int
//    public let naturalUnits: Int
//    public let defaultVisibility: Bool
//    public let defaultOrdinalLevel: Int?
//    public let reliabilityGasPricePercent: Int
//    public let reliabilityGasLimitPercent: Int
//    public let defaultGasPriceGwei: Int
//    public let defaultGasLimit: Int
//    public let warningGasPriceGwei: Int
//    public let transferDecimals: Int
//    
//    public var logo: UIImage {
//        .asset(named: "\(symbol.lowercased())_wallet")
//            ?? .asset(named: "ethereum_wallet")
//            ?? UIImage()
//    }
////    public var logo: UIImage {
////            let fileManager = FileManager.default
////            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PreloadedImages")
////
////            return fileManager.imageScale(named: "\(symbol.lowercased())_wallet", in: directory)
////                ?? UIImage(named: "ethereum_wallet")
////                ?? UIImage()
////        }
//
//    enum CodingKeys: String, CodingKey {
//        case symbol
//        case name
//        case explorerAddress
//        case decimals
//        case cryptoTransferDecimals
//        case defaultVisibility
//        case defaultOrdinalLevel
//        case reliabilityGasPricePercent
//        case reliabilityGasLimitPercent
//        case defaultGasPriceGwei
//        case defaultGasLimit
//        case warningGasPriceGwei
//    }
//    
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        
//        self.symbol = try container.decode(String.self, forKey: .symbol)
//        self.name = try container.decode(String.self, forKey: .name)
//        self.contractAddress = try container.decodeIfPresent(String.self, forKey: .explorerAddress) ?? ""
//        self.decimals = try container.decode(Int.self, forKey: .decimals)
//        self.naturalUnits = decimals
//        self.transferDecimals = try container.decode(Int.self, forKey: .cryptoTransferDecimals)
//        
//        self.defaultVisibility = try container.decodeIfPresent(Bool.self, forKey: .defaultVisibility) ?? false
//        self.defaultOrdinalLevel = try container.decodeIfPresent(Int.self, forKey: .defaultOrdinalLevel)
//        self.reliabilityGasPricePercent = try container.decodeIfPresent(Int.self, forKey: .reliabilityGasPricePercent) ?? 0
//        self.reliabilityGasLimitPercent = try container.decodeIfPresent(Int.self, forKey: .reliabilityGasLimitPercent) ?? 0
//        self.defaultGasPriceGwei = try container.decodeIfPresent(Int.self, forKey: .defaultGasPriceGwei) ?? 0
//        self.defaultGasLimit = try container.decodeIfPresent(Int.self, forKey: .defaultGasLimit) ?? 0
//        self.warningGasPriceGwei = try container.decodeIfPresent(Int.self, forKey: .warningGasPriceGwei) ?? 0
//        
//    }
//}
public struct ERC20Token: Sendable {
    public let symbol: String
    public let name: String
    public let contractAddress: String
    public let decimals: Int
    public let naturalUnits: Int
    public let defaultVisibility: Bool
    public let defaultOrdinalLevel: Int?
    public let reliabilityGasPricePercent: Int
    public let reliabilityGasLimitPercent: Int
    public let defaultGasPriceGwei: Int
    public let defaultGasLimit: Int
    public let warningGasPriceGwei: Int
    public let transferDecimals: Int
    
    public var logo: UIImage {
        .asset(named: "\(symbol.lowercased())_wallet")
            ?? .asset(named: "ethereum_wallet")
            ?? UIImage()
    }
}
