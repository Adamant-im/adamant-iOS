//
//  Transactions.swift
//  Lisk
//
//  Created by Andrew Barba on 1/2/18.
//

import Foundation

/// Type of transactions supported on Lisk network
public enum TransactionType: UInt8, Encodable {
    case transfer = 0
    case registerSecondPassphrase = 1
    case registerDelegate = 2
    case castVotes = 3
    case registerMultisignature = 4
    case createDapp = 5
    case transferIntoDapp = 6
    case transferOutOfDapp = 7
}

/// Transactions - https://docs.lisk.io/docs/lisk-api-080-transactions
public struct Transactions: APIService {

    /// Client used to send requests
    public let client: APIClient

    /// Init
    public init(client: APIClient = .shared) {
        self.client = client
    }
}

// MARK: - Submit

extension Transactions {

    /// Submit a signed transaction to the network
    public func submit(signedTransaction: LocalTransaction, completionHandler: @escaping (Response<TransactionBroadcastResponse>) -> Void) {
        guard signedTransaction.isSigned else {
            let response = APIError(message: "Invalid Transaction - Transaction has not been signed")
            return completionHandler(.error(response: response))
        }

        client.post(path: "transactions", options: signedTransaction.requestOptions, completionHandler: completionHandler)
    }
    
    public func submit(signedTransaction: RequestOptions, completionHandler: @escaping (Response<TransactionSubmitResponse>) -> Void) {
        client.post(path: "transactions", options: signedTransaction, completionHandler: completionHandler)
    }
}

// MARK: - Send

extension Transactions {

    /// Transfer LSK to a Lisk address using Local Signing
    public func transfer(lsk: Double, to recipient: String, passphrase: String, secondPassphrase: String? = nil, completionHandler: @escaping (Response<TransactionBroadcastResponse>) -> Void) {
        do {
            let transaction = LocalTransaction(.transfer, lsk: lsk, recipientId: recipient)
            let signedTransaction = try transaction.signed(passphrase: passphrase, secondPassphrase: secondPassphrase)
            submit(signedTransaction: signedTransaction, completionHandler: completionHandler)
        } catch {
            let response = APIError(message: error.localizedDescription)
            completionHandler(.error(response: response))
        }
    }
    
    /// Transfer LSK to a Lisk address using Local Signing with KeyPair
    public func transfer(lsk: Double, to recipient: String, keyPair: KeyPair, completionHandler: @escaping (Response<TransactionBroadcastResponse>) -> Void) {
        do {
            let transaction = LocalTransaction(.transfer, lsk: lsk, recipientId: recipient)
            let signedTransaction = try transaction.signed(keyPair: keyPair)
            submit(signedTransaction: signedTransaction, completionHandler: completionHandler)
        } catch {
            let response = APIError(message: error.localizedDescription)
            completionHandler(.error(response: response))
        }
    }
}

// MARK: - Register Second Passphrase

extension Transactions {

    /// Register a second passphrase
    public func registerSecondPassphrase(_ secondPassphrase: String, passphrase: String, completionHandler: @escaping (Response<TransactionBroadcastResponse>) -> Void) {
        do {
            let (publicKey, _) = try Crypto.keys(fromPassphrase: secondPassphrase)
            let asset = ["signature": ["publicKey": publicKey]]
            let transaction = LocalTransaction(.registerSecondPassphrase, amount: 0, asset: asset)
            let signedTransaction = try transaction.signed(passphrase: passphrase, secondPassphrase: nil)
            submit(signedTransaction: signedTransaction, completionHandler: completionHandler)
        } catch {
            let response = APIError(message: error.localizedDescription)
            completionHandler(.error(response: response))
        }
    }
}

// MARK: - List

extension Transactions {

    /// List transaction objects
    public func transactions(id: String? = nil, block: String? = nil, sender: String? = nil, recipient: String? = nil, senderIdOrRecipientId: String? = nil, limit: UInt? = nil, offset: UInt? = nil, sort: APIRequest.Sort? = nil, completionHandler: @escaping (Response<TransactionsResponse>) -> Void) {
        var options: RequestOptions = [:]
        if let value = id { options["id"] = value }
        if let value = block { options["blockId"] = value }
        if let value = sender { options["senderId"] = value }
        if let value = recipient { options["recipientId"] = value }
        if let value = senderIdOrRecipientId { options["senderIdOrRecipientId"] = value }
        if let value = limit { options["limit"] = value }
        if let value = offset { options["offset"] = value }
        if let value = sort?.value { options["sort"] = value }

        client.get(path: "transactions", options: options, completionHandler: completionHandler)
    }
}
