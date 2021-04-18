//
//  LocalTransaction.swift
//  Lisk
//
//  Created by Andrew Barba on 1/7/18.
//

import Foundation

/// Struct to represent a local transaction with the ability to locally sign via a secret passphrase
public struct LocalTransaction {

    /// Transaction asset
    public typealias Asset = [String: Any]

    /// Type of transaction
    public let type: TransactionType

    /// Amount of Lisk to send
    public let amount: UInt64

    /// Fee to complete the transaction
    public let fee: UInt64

    /// The recipient of the amount being sent
    public let recipientId: String?

    /// Timestamp relative to Genesis epoch time
    public let timestamp: UInt32

    /// Additional transaction data
    public let asset: Asset?

    /// Id of the transaction, only set after the transaction is signed
    public private(set) var id: String?

    /// Public key extracted from secret, only set after the transaction is signed
    public private(set) var senderPublicKey: String?

    /// Signature of the transaction, only set after the transaction is signed
    public private(set) var signature: String?

    /// Second sign-signature of the transaction, only set after the transaction is signed
    public private(set) var signSignature: String?

    /// Has this transaction been signed already
    public var isSigned: Bool {
        return id != nil && senderPublicKey != nil && signature != nil
    }

    /// Has this transaction been signed with a secret and second secret
    public var isSecondSigned: Bool {
        return isSigned && signSignature != nil
    }

    /// Init
    public init(_ type: TransactionType, amount: UInt64, recipientId: String? = nil, timestamp: UInt32? = nil, asset: Asset? = nil) {
        self.type = type
        self.amount = amount
        self.fee = LocalTransaction.transactionFee(type: type)
        self.recipientId = recipientId
        self.timestamp = timestamp ?? Crypto.timeIntervalSinceGenesis()
        self.asset = asset
        self.id = nil
        self.senderPublicKey = nil
        self.signature = nil
        self.signSignature = nil
    }

    /// Init
    public init(_ type: TransactionType, lsk: Double, recipientId: String? = nil, timestamp: UInt32? = nil, asset: Asset? = nil) {
        let amount = Crypto.fixedPoint(amount: lsk)
        self.init(type, amount: amount, recipientId: recipientId, timestamp: timestamp, asset: asset)
    }

    /// Init, copies transaction
    public init(transaction: LocalTransaction) {
        self.type = transaction.type
        self.amount = transaction.amount
        self.fee = transaction.fee
        self.recipientId = transaction.recipientId
        self.senderPublicKey = transaction.senderPublicKey
        self.timestamp = transaction.timestamp
        self.asset = transaction.asset
        self.id = transaction.id
        self.signature = transaction.signature
        self.signSignature = transaction.signSignature
    }

    /// Returns a new signed transaction based on this transaction
    public func signed(passphrase: String, secondPassphrase: String? = nil) throws -> LocalTransaction {
        let keyPair = try Crypto.keyPair(fromPassphrase: passphrase)
        let secondKeyPair: KeyPair?
        if let secondPassphrase = secondPassphrase {
            secondKeyPair = try Crypto.keyPair(fromPassphrase: secondPassphrase)
        } else {
            secondKeyPair = nil
        }
        return try signed(keyPair: keyPair, secondKeyPair: secondKeyPair)
    }

    /// Signs the current transaction
    public mutating func sign(passphrase: String, secondPassphrase: String? = nil) throws {
        let transaction = try signed(passphrase: passphrase, secondPassphrase: secondPassphrase)
        self.id = transaction.id
        self.senderPublicKey = transaction.senderPublicKey
        self.signature = transaction.signature
        self.signSignature = transaction.signSignature
    }

    /// Returns a new signed transaction based on this transaction
    public func signed(keyPair: KeyPair, secondKeyPair: KeyPair? = nil) throws -> LocalTransaction {
        var transaction = LocalTransaction(transaction: self)
        transaction.senderPublicKey = keyPair.publicKeyString
        transaction.signature = LocalTransaction.generateSignature(bytes: transaction.bytes, keyPair: keyPair)
        if let secondKeyPair = secondKeyPair, transaction.type != .registerSecondPassphrase {
            transaction.signSignature = LocalTransaction.generateSignature(bytes: transaction.bytes, keyPair: secondKeyPair)
        }
        transaction.id = LocalTransaction.generateId(bytes: transaction.bytes)
        return transaction
    }

    /// Signs the current transaction
    public mutating func sign(keyPair: KeyPair, secondKeyPair: KeyPair? = nil) throws {
        let transaction = try signed(keyPair: keyPair, secondKeyPair: secondKeyPair)
        self.id = transaction.id
        self.senderPublicKey = transaction.senderPublicKey
        self.signature = transaction.signature
        self.signSignature = transaction.signSignature
    }

    private static func generateId(bytes: [UInt8]) -> String {
        let hash = SHA256(bytes).digest()
        let id = Crypto.byteIdentifier(from: hash)
        return "\(id)"
    }

    private static func generateSignature(bytes: [UInt8], keyPair: KeyPair) -> String {
        let hash = SHA256(bytes).digest()
        return keyPair.sign(hash).hexString()
    }

    private static func transactionFee(type: TransactionType) -> UInt64 {
        switch type {
        case .transfer: return Constants.Fee.transfer
        case .registerSecondPassphrase: return Constants.Fee.signature
        case .registerDelegate: return Constants.Fee.delegate
        case .castVotes: return Constants.Fee.vote
        case .registerMultisignature: return Constants.Fee.multisignature
        case .createDapp: return Constants.Fee.dapp
        case .transferIntoDapp: return Constants.Fee.inTransfer
        case .transferOutOfDapp: return Constants.Fee.outTransfer
        }
    }
}

// MARK: - Bytes

extension LocalTransaction {

    var bytes: [UInt8] {
        return
            typeBytes +
            timestampBytes +
            senderPublicKeyBytes +
            recipientIdBytes +
            amountBytes +
            assetBytes +
            signatureBytes +
            signSignatureBytes
    }

    var typeBytes: [UInt8] {
        return [type.rawValue]
    }

    var timestampBytes: [UInt8] {
        return BytePacker.pack(timestamp, byteOrder: .littleEndian)
    }

    var senderPublicKeyBytes: [UInt8] {
        return senderPublicKey?.hexBytes() ?? []
    }

    var recipientIdBytes: [UInt8] {
        guard
            let value = recipientId?.replacingOccurrences(of: "L", with: ""),
            let number = UInt64(value) else { return [UInt8](repeating: 0, count: 8) }
        return BytePacker.pack(number, byteOrder: .bigEndian)
    }

    var amountBytes: [UInt8] {
        return BytePacker.pack(amount, byteOrder: .littleEndian)
    }

    var signatureBytes: [UInt8] {
        return signature?.hexBytes() ?? []
    }

    var signSignatureBytes: [UInt8] {
        return signSignature?.hexBytes() ?? []
    }

    var assetBytes: [UInt8] {
        guard
            let data = asset as? [String: [String: String]],
            let signature = data["signature"],
            let publicKey = signature["publicKey"]
            else { return [] }
        return publicKey.hexBytes()
    }
}

// MARK: - Request Options

extension LocalTransaction {

    var requestOptions: RequestOptions {
        var options: RequestOptions = [
            "id": id ?? NSNull(),
            "type": type.rawValue,
            "amount": "\(amount)",
            "fee": "\(fee)",
            "recipientId": recipientId ?? NSNull(),
            "senderPublicKey": senderPublicKey ?? NSNull(),
            "timestamp": timestamp,
            "asset": asset ?? Asset(),
            "signature": signature ?? NSNull()
        ]
        
        if let value = signSignature { options["signSignature"] = value }
        
        return options
    }
}
