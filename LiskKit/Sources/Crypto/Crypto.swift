//
//  Crypto.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/1/18.
//

import Foundation
import Clibsodium
import CryptoSwift

public struct Crypto {

    /// Generate public and private keys from a given secret
    public static func keys(fromPassphrase passphrase: String) throws -> (publicKey: String, privateKey: String) {
        let keyPair = try self.keyPair(fromPassphrase: passphrase)
        return (keyPair.publicKeyString, keyPair.privateKeyString)
    }

    /// Generate key pair from a given secret
    public static func keyPair(fromPassphrase passphrase: String) throws -> KeyPair {
        let bytes = SHA256(passphrase).digest()
        return try KeyPair(seed: bytes)
    }
    
    /// Generate key pair from a given secret and salt
    public static func keyPair(fromPassphrase passphrase: String, salt: String) throws -> KeyPair {
        let bytes = try Crypto.seed(passphrase: passphrase, salt: salt)
        return try KeyPair(seed: bytes)
    }
    
    private static func seed(passphrase: String, salt: String = "mnemonic") throws -> [UInt8] {
        let password = passphrase.decomposedStringWithCompatibilityMapping
        let salt = salt.decomposedStringWithCompatibilityMapping
        
        return try PKCS5.PBKDF2(password: password.hexBytes(), salt: salt.hexBytes(), iterations: 2048, keyLength: 32, variant: HMAC.Variant.sha256).calculate()
    }

    /// Extract Lisk address from a public key
    public static func address(fromPublicKey publicKey: String) -> String {
        let bytes = SHA256(publicKey.hexBytes()).digest()
        let identifier = byteIdentifier(from: bytes)
        return "\(identifier)L"
    }

    /// Sign a message
    public static func signMessage(_ message: String, passphrase: String) throws -> String {
        let keyPair = try self.keyPair(fromPassphrase: passphrase)
        let bytes = keyPair.sign(message.hexBytes())
        return bytes.hexString()
    }

    /// Verify a message
    public static func verifyMessage(_ message: String, signature: String, publicKey: String) throws -> Bool {
        guard signature.count == 64 else {
            throw CryptoError.invalidSignatureLength
        }
        
        let signature = signature.hexBytes()
        let message = message.hexBytes()
        let publicKey = publicKey.hexBytes()
        
        
        guard .SUCCESS == crypto_sign_verify_detached(
            signature,
            message,
            UInt64(message.count),
            publicKey).exitCode else { throw CryptoError.invalidSignature }
        
        return true
    }

    /// Epoch time relative to genesis block
    public static func timeIntervalSinceGenesis(offset: TimeInterval = 0) -> UInt32 {
        let now = Date().timeIntervalSince1970 + offset
        let diff = max(0, now - Constants.Time.epochSeconds)
        return UInt32(diff)
    }

    /// Multiplies a given amount by Lisk fixed point
    public static func fixedPoint(amount: Double) -> UInt64 {
        return UInt64(amount * Constants.fixedPoint)
    }

    internal static func byteIdentifier(from bytes: [UInt8]) -> String {
        guard bytes.count >= 8 else { return "" }
        let leadingBytes = bytes[0..<8].reversed()
        let data = Data(Array(leadingBytes))
        let value = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
        return "\(value)"
    }
}

extension KeyPair {

    /// Hex representation of public key
    public var publicKeyString: String {
        return publicKey.hexString()
    }

    /// Hex representation of private key
    public var privateKeyString: String {
        return privateKey.hexString()
    }
}

extension String {

    internal func hexBytes() -> [UInt8] {
        return (0..<count/2).reduce([]) { res, i in
            let indexStart = index(startIndex, offsetBy: i * 2)
            let indexEnd = index(indexStart, offsetBy: 2)
            let substring = self[indexStart..<indexEnd]
            return res + [UInt8(substring, radix: 16) ?? 0]
        }
    }
}

extension Sequence where Self.Element == UInt8 {

    internal func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

private enum ExitCode {
    case SUCCESS
    case FAILURE
    
    init (from int: Int32) {
        switch int {
        case 0:  self = .SUCCESS
        default: self = .FAILURE
        }
    }
}

private extension Int32 {
    var exitCode: ExitCode { return ExitCode(from: self) }
}

public enum CryptoError: Error {
    case seedGenerationFailed
    case invalidSeedLength
    case invalidScalarLength
    case invalidPublicKeyLength
    case invalidPrivateKeyLength
    case invalidSignatureLength
    case invalidSignature
    case keysGenerationFailed
    case signingFailed
}

public class KeyPair {
    
    public let publicKey: [UInt8]
    public let privateKey: [UInt8]
    
    public init(publicKey: [UInt8], privateKey: [UInt8]) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    public convenience init(seed: [UInt8]) throws {
        var publicKey = [UInt8](repeating: 0, count: Int(crypto_sign_publickeybytes()))
        var privateKey = [UInt8](repeating: 0, count: Int(crypto_sign_secretkeybytes()))
        
        guard .SUCCESS == crypto_sign_seed_keypair(
            &publicKey,
            &privateKey,
            seed
            ).exitCode else { throw CryptoError.keysGenerationFailed }
        
        self.init(publicKey: publicKey, privateKey: privateKey)
    }
    
    public func sign(_ message: [UInt8]) -> [UInt8] {
        var signature = [UInt8](repeating: 0, count: Int(crypto_sign_bytes()))
        
        guard .SUCCESS == crypto_sign_detached (
            &signature,
            nil,
            message, UInt64(message.count),
            privateKey
            ).exitCode else {
                return [UInt8]()
        }
        
        return signature
    }
    
}
