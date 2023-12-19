//
//  Accounts.swift
//  Lisk
//
//  Created by Andrew Barba on 12/31/17.
//

import Foundation

/// Accounts - https://docs.lisk.io/docs/lisk-api-080-accounts
public struct Accounts: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - List

extension Accounts {

    /// Retrieve accounts
    public func legacyAccounts(address: String? = nil, publicKey: String? = nil, secondPublicKey: String? = nil, username: String? = nil, limit: Int? = nil, offset: Int? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<LegacyAccountsResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = address { options["address"] = value }
        if let value = publicKey { options["publicKey"] = value }
        if let value = secondPublicKey { options["secondPublicKey"] = value }
        if let value = username { options["username"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "accounts", options: options, completionHandler: completionHandler)
    }

    // New API

    public func accounts(address: String, completionHandler: @escaping (Response<AccountsResponse>) -> Void) {
        client.get(path: "accounts/\(address)", options: nil, completionHandler: completionHandler)
    }
    
    public func balance(address: String) async throws -> Balance? {
        let balances: BalancesResponse = try await client.request(
            method: "token_getBalances",
            params: ["address": address]
        )
        return balances.balances.first(where: { $0.tokenID == Constants.tokenID })
    }
    
    public func nonce(address: String) async throws -> String {
        let data: AuthAccount = try await client.request(
            method: "auth_getAuthAccount",
            params: ["address": address]
        )
        return data.nonce
    }
    
    public func lastBlock() async throws -> Block {
        try await client.request(
            method: "chain_getLastBlock",
            params: [:]
        )
    }
    
    public func getFees() async throws -> ServiceFeeModel {
        try await client.request(method: "fee_getMinFeePerByte", params: [:])
    }
}
