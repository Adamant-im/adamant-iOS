//
//  EthApiCore.swift
//  Adamant
//
//  Created by Andrew G on 30.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
import web3swift
import Web3Core

actor EthApiCore {
    let apiCore: APICoreProtocol
    private(set) var keystoreManager: KeystoreManager?
    private var web3Cache: [URL: Web3] = .init()
    
    func performRequest<Success>(
        origin: NodeOrigin,
        _ body: @escaping @Sendable (_ web3: Web3) async throws -> Success
    ) async -> WalletServiceResult<Success> {
        switch await getWeb3(origin: origin) {
        case let .success(web3):
            do {
                return .success(try await body(web3))
            } catch {
                return .failure(mapError(error))
            }
        case let .failure(error):
            return .failure(error)
        }
    }
    
    func setKeystoreManager(_ keystoreManager: KeystoreManager) {
        self.keystoreManager = keystoreManager
        web3Cache = .init()
    }
    
    init(apiCore: APICoreProtocol) {
        self.apiCore = apiCore
    }
}

extension EthApiCore: BlockchainHealthCheckableService {
    func getStatusInfo(origin: NodeOrigin) async -> WalletServiceResult<NodeStatusInfo> {
        let startTimestamp = Date.now.timeIntervalSince1970
        
        let response = await apiCore.sendRequestRPC(
            origin: origin,
            path: .empty,
            requests: [
                .init(method: EthApiComand.blockNumberMethod),
                .init(method: EthApiComand.clientVersionMethod)
            ]
        )
        
        guard case let .success(data) = response else {
            return .failure(.internalError(.parsingFailed))
        }
        
        let blockNumberData = data.first(
            where: { $0.id == EthApiComand.blockNumberMethod }
        )
        let clientVersionData = data.first(
            where: { $0.id == EthApiComand.clientVersionMethod }
        )
        
        guard
            let blockNumberData = blockNumberData,
            let clientVersionData = clientVersionData
        else {
            return .failure(.internalError(.parsingFailed))
        }
        
        let blockNumber = String(decoding: blockNumberData.result, as: UTF8.self)
        let clientVersion = String(decoding: clientVersionData.result, as: UTF8.self)
        
        guard let height = hexStringToDouble(blockNumber) else {
            return .failure(.internalError(.parsingFailed))
        }
        
        return .success(.init(
            ping: Date.now.timeIntervalSince1970 - startTimestamp,
            height: Int(height),
            wsEnabled: false,
            wsPort: nil,
            version: extractVersion(from: clientVersion).flatMap { .init($0) }
        ))
    }
}

private extension EthApiCore {
    func getWeb3(origin: NodeOrigin) async -> WalletServiceResult<Web3> {
        guard let url = origin.asURL() else {
            return .failure(.internalError(.endpointBuildFailed))
        }
        
        if let web3 = web3Cache[url] {
            return .success(web3)
        }
        
        do {
            let web3 = try await Web3.new(url)
            web3.addKeystoreManager(keystoreManager)
            web3Cache[url] = web3
            return .success(web3)
        } catch {
            return .failure(.internalError(
                message: error.localizedDescription,
                error: error
            ))
        }
    }
}

private func mapError(_ error: Error) -> WalletServiceError {
    if let error = error as? Web3Error {
        return error.asWalletServiceError()
    } else if let error = error as? ApiServiceError {
        return error.asWalletServiceError()
    } else if let error = error as? WalletServiceError {
        return error
    } else if let _ = error as? URLError {
        return .networkError
    } else {
        return .remoteServiceError(message: error.localizedDescription)
    }
}

private struct EthApiComand {
    static let blockNumberMethod: String = "eth_blockNumber"
    static let clientVersionMethod: String = "web3_clientVersion"
}

private func hexStringToDouble(_ hexString: String) -> UInt64? {
    let cleanString = hexString.replacingOccurrences(of: "0x", with: "")
    
    if let hexValue = UInt64(cleanString, radix: 16) {
        return hexValue
    }
    
    return nil
}

private func extractVersion(from input: String) -> String? {
    let pattern = #"^(.+?/v\d+\.\d+\.\d+).*?$"#
    
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    if let match = regex?.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count)) {
        if let range = Range(match.range(at: 1), in: input) {
            return String(input[range])
        }
    }

    return nil
}
