//
//  CoinsMapper.swift
//  AdamantWalletsKit
//
//  Created by Sergei Veretennikov on 25.03.2025.
//

// Everything here goes synchronousely here's no data races or race conditions

import Foundation

public enum AnyBlockchain: Hashable {
    public enum DeclaredBlockchain: String {
        case ethereum
    }

    case declared(DeclaredBlockchain)
    case undeclared(String)

    public var rawValue: String {
        switch self {
        case let .declared(chain):
            chain.rawValue
        case let .undeclared(undeclared):
            undeclared
        }
    }

    init(from raw: String) {
        if let declared = DeclaredBlockchain(rawValue: raw) {
            self = .declared(declared)
        } else {
            self = .undeclared(raw)
        }
    }
}

final class BlockchainTokensStorage {
    private let chain: AnyBlockchain
    var tokens: [String: CoinInfoDTO] = [:]

    init(chain: AnyBlockchain) {
        self.chain = chain
    }

    func addToken(coin: CoinInfoDTO) {
        tokens[coin.symbol] = coin
    }

    func getToken(token symbol: String) -> CoinInfoDTO? {
        tokens[symbol]
    }
}

public protocol AnyTokensStorage: AnyObject {
    subscript(symbol: String) -> CoinInfoDTO? { get }
    subscript(symbol: String, chain: AnyBlockchain?) -> CoinInfoDTO? { get }
    subscript(chain: AnyBlockchain) -> [String: CoinInfoDTO]? { get }

    func loadTokens()
    func getCoin(_ coin: String) -> CoinInfoDTO?
}

public final class TokensStorage: AnyTokensStorage {
    private var blockchains: [AnyBlockchain] = []
    private var blockchaisTokensStorage: [AnyBlockchain: BlockchainTokensStorage] = [:]
    private var coinsStorage: [String: CoinInfoDTO] = [:]

    public init() {}

    /// Coin from storage
    public subscript(symbol: String) -> CoinInfoDTO? {
        if let coin = getCoin(symbol) {
            return coin
        }
        return nil
    }

    /// Get token from storage for specific chain, or try to get coin if there is no chain in storage
    public subscript(symbol: String, chain: AnyBlockchain? = nil) -> CoinInfoDTO? {
        if let chain {
            return blockchaisTokensStorage[chain]?.getToken(token: symbol)
        }
        if let coin = getCoin(symbol) {
            return coin
        }
        return nil
    }

    /// Get list of tokens for chain
    public subscript(chain: AnyBlockchain) -> [String: CoinInfoDTO]? {
        blockchainTokens(for: chain)?.tokens
    }

    public func getCoin(_ coin: String) -> CoinInfoDTO? {
        coinsStorage[coin]
    }

    public func loadTokens() {
        loadBlockchains()
        loadMainTokensForBlockchains()
        loadBaseOfSpecificTokens()
        loadCoins()
    }

    private func loadCoins() {
        guard let counsResource = Bundle.module.url(forResource: "general", withExtension: nil),
            let enumerator = FileManager.default.enumerator(at: counsResource, includingPropertiesForKeys: nil)
        else {
            return
        }

        let allGeneral: [String] = enumerator.compactMap {
            guard let url = $0 as? URL, url.lastPathComponent == "info.json" else { return nil }
            return url.deletingLastPathComponent().lastPathComponent
        }

        allGeneral.forEach {
            addCoinFromGeneralIfNeeded(folderName: $0)
        }
    }

    private func addCoinFromGeneralIfNeeded(folderName: String) {
        guard let infoJson = Bundle.module.url(forResource: "general/\(folderName)/info", withExtension: "json"),
            let data = try? Data(contentsOf: infoJson),
            let coinInfo = try? JSONDecoder().decode(CoinInfoDTO.self, from: data),
            coinInfo._type == .coin, coinInfo.isActive
        else {
            return
        }
        coinsStorage[coinInfo.symbol] = coinInfo
    }

    private func loadBlockchains() {
        guard let blockchainsResourceURL = Bundle.module.url(forResource: "blockchains", withExtension: nil),
            let blockhainsList = FileManager.default.enumerator(at: blockchainsResourceURL, includingPropertiesForKeys: nil)
        else {
            return
        }

        guard let firstFolder = (blockhainsList.nextObject() as? URL) else { return }
        blockchains.append(.init(from: firstFolder.lastPathComponent))
        let depth = firstFolder.pathComponents.count
        while let element = blockhainsList.nextObject() as? URL {
            if depth == element.pathComponents.count {
                blockchains.append(.init(from: element.lastPathComponent))
            }
        }
    }

    private func loadMainTokensForBlockchains() {
        blockchains.forEach {
            loadMainTokenFor(chain: $0)
        }
    }

    private func loadBaseOfSpecificTokens() {
        blockchains.forEach { chain in
            let specificTokenList = tokenListForChain(chain: chain)
            for tokenSymbol in specificTokenList {
                guard let baseCoin = loadMainTokenFor(chain: chain),
                    let generalMerge = mergeTokenFrom(path: "general/\(tokenSymbol)", base: baseCoin),
                    let generalMainCoin = mergeTokenFrom(path: "blockchains/\(chain.rawValue)", base: generalMerge),
                    let blockchainMerge = mergeTokenFrom(path: "blockchains/\(chain.rawValue)/\(tokenSymbol)", base: generalMainCoin),
                    blockchainMerge.isActive, blockchainMerge.symbol != baseCoin.symbol
                else {
                    continue
                }

                blockchaisTokensStorage[chain]?.addToken(coin: blockchainMerge)
            }
        }
    }

    private func tokenListForChain(chain: AnyBlockchain) -> [String] {
        guard let specificBlockchainsResourceURL = Bundle.module.url(forResource: "blockchains/\(chain.rawValue)", withExtension: nil),
            let tokensList = FileManager.default.enumerator(at: specificBlockchainsResourceURL, includingPropertiesForKeys: nil)
        else {
            return []
        }

        let blockchainTokenList: [String] = tokensList.compactMap { token in
            guard let token = token as? URL,
                token.lastPathComponent == "info.json"
            else { return nil }
            return token.deletingLastPathComponent().lastPathComponent
        }

        return blockchainTokenList
    }

    private func mergeTokenFrom(path: String, base: CoinInfoDTO) -> CoinInfoDTO? {
        guard let tokenURLGeneral = Bundle.module.url(forResource: "\(path)/info", withExtension: "json"),
            let tokenData = try? Data(contentsOf: tokenURLGeneral),
            let tokenDict = try? JSONSerialization.jsonObject(with: tokenData) as? [String: Any],
            let baseData = try? JSONEncoder().encode(base),
            var baseDict = try? JSONSerialization.jsonObject(with: baseData) as? [String: Any]
        else {
            return nil
        }

        tokenDict.forEach { key, value in
            baseDict[key] = value
        }

        guard let finalData = try? JSONSerialization.data(withJSONObject: baseDict),
            let mergedCoin = try? JSONDecoder().decode(CoinInfoDTO.self, from: finalData)
        else {
            return nil
        }
        return mergedCoin
    }

    @discardableResult
    private func loadMainTokenFor(chain: AnyBlockchain) -> CoinInfoDTO? {
        guard let mainCoin = Bundle.module.url(forResource: "general/\(chain.rawValue)/info", withExtension: "json"),
            let data = try? Data(contentsOf: mainCoin, options: .alwaysMapped)
        else {
            return nil
        }

        guard let coinInfo = try? JSONDecoder().decode(CoinInfoDTO.self, from: data),
            coinInfo.isActive
        else { return nil }

        if coinsStorage[coinInfo.symbol] == nil {
            blockchaisTokensStorage[chain] = .init(chain: chain)
            coinsStorage[coinInfo.symbol] = coinInfo
        }
        return coinInfo
    }

    private func blockchainTokens(for blockchain: AnyBlockchain) -> BlockchainTokensStorage? {
        blockchaisTokensStorage[blockchain]
    }
}

extension CoinInfoDTO {
    fileprivate enum CoinType {
        case coin
        case token
    }

    fileprivate var isActive: Bool {
        status == "active"
    }

    fileprivate var _type: CoinType? {
        switch type {
        case "coin": .coin
        case "token": .token
        default: nil
        }
    }
}
