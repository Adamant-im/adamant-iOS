//
//  WebToken.swift
//  Lisk
//
//  Created by Andrew Barba on 5/15/18.
//

import Foundation

public enum WebTokenError: Error {
    case expired
    case invalid
    case unauthorized
}

public struct WebToken {

    /// Time the token was created
    let timestamp: UInt32

    /// Public key of the sender
    let publicKey: String

    /// Signed message of the tokens timestamp
    let signature: String

    /// Address from the tokens public key
    var address: String {
        return Crypto.address(fromPublicKey: publicKey)
    }

    /// Initialized from a passphrase
    public init(passphrase: String, offset: TimeInterval = 0) throws {
        self.timestamp = Crypto.timeIntervalSinceGenesis(offset: offset)
        self.publicKey = try Crypto.keys(fromPassphrase: passphrase).publicKey
        self.signature = try Crypto.signMessage("\(timestamp)", passphrase: passphrase)
    }

    /// Initialized from a token string, throws an error if:
    ///   - Token string is invalid
    ///   - Token string fails signature check
    ///   - Token is expired
    public init(tokenString: String, expiration: TimeInterval = 30) throws {
        let parts = tokenString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ".")

        guard parts.count == 3, let timestamp = UInt32(parts[0]) else {
            throw WebTokenError.invalid
        }

        let publicKey = parts[1]
        let signature = parts[2]

        guard try Crypto.verifyMessage("\(timestamp)", signature: signature, publicKey: publicKey) else {
            throw WebTokenError.unauthorized
        }

        guard timestamp >= Crypto.timeIntervalSinceGenesis(offset: -expiration) else {
            throw WebTokenError.expired
        }

        self.timestamp = timestamp
        self.publicKey = publicKey
        self.signature = signature
    }

    /// Returns a string in the format {timestamp}.{publicKey}.{signature(timestamp)}
    public func tokenString() -> String {
        return "\(timestamp).\(publicKey).\(signature)"
    }

    /// Is the token expired relative to an expiration time from now
    public func isExpired(expiration: TimeInterval = 30) -> Bool {
        return timestamp < Crypto.timeIntervalSinceGenesis(offset: -expiration)
    }
}
