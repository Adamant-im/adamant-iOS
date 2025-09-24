//
//  EthApiService.swift
//  Adamant
//
//  Created by Andrew G on 13.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import CommonKit
import Foundation
@preconcurrency import Web3Core
import web3swift

class EthApiService: EthApiServiceProtocol, @unchecked Sendable {
    let api: BlockchainHealthCheckWrapper<EthApiCore>

    var keystoreManager: KeystoreManager? {
        get async { await api.service.keystoreManager }
    }

    @MainActor
    var nodesInfoPublisher: AnyObservable<NodesListInfo> { api.nodesInfoPublisher }

    @MainActor
    var nodesInfo: NodesListInfo { api.nodesInfo }

    func healthCheck() { api.healthCheck() }

    init(api: BlockchainHealthCheckWrapper<EthApiCore>) {
        self.api = api
    }

    func requestWeb3<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (Web3) async throws -> Output
    ) async -> WalletServiceResult<Output> {
        await api.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await core.performRequest(origin: origin, request)
        }
    }

    func requestApiCore<Output>(
        waitsForConnectivity: Bool,
        _ request: @Sendable @escaping (APICoreProtocol, NodeOrigin) async -> ApiServiceResult<Output>
    ) async -> WalletServiceResult<Output> {
        await api.request(waitsForConnectivity: waitsForConnectivity) { core, origin in
            await request(core.apiCore, origin).mapError { $0.asWalletServiceError() }
        }
    }

    func getStatusInfo() async -> WalletServiceResult<NodeStatusInfo> {
        await api.request(waitsForConnectivity: false) { core, origin in
            await core.getStatusInfo(origin: origin)
        }
    }

    func setKeystoreManager(_ keystoreManager: KeystoreManager) async {
        await api.service.setKeystoreManager(keystoreManager)
    }
}

// https://github.com/Adamant-im/adamant-iOS/pull/855/files
extension EthApiService {
    func fetchBlockTimestamp(blockNumberHex: String) async throws -> Date {
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_getBlockByNumber",
            "params": [blockNumberHex, false],
            "id": 1
        ]

        let result: EthBlockResponse = try await requestApiCore(waitsForConnectivity: false) { core, origin in
            await core.sendRequestJsonResponse(
                origin: origin,
                path: "",
                method: .post,
                jsonParameters: body
            )
        }.get()

        guard
            let timestampHex = result.result?.timestamp,
            let timestampInt = UInt64(HexUtils.trimHexPrefix(from: timestampHex), radix: 16)
        else {
            throw WalletServiceError.remoteServiceError(message: "Invalid timestamp in block response")
        }

        return Date(timeIntervalSince1970: TimeInterval(timestampInt))
    }
}

struct HexUtils {
    static func trimHexPrefix(from hexString: String) -> String {
        hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
    }
}
