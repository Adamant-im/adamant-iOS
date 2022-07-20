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
        
        return try PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: 2048, keyLength: 32, variant: HMAC.Variant.sha256).calculate()
    }

    /// Extract Lisk address from a public key
    public static func address(fromPublicKey publicKey: String) -> String {
        let bytes = SHA256(publicKey.hexBytes()).digest()
        let identifier = byteIdentifier(from: bytes)
        return "\(identifier)L"
    }

    static let PREFIX_LISK = "lsk"
    static let CHARSET = Array("zxvcpmbn3465o978uyrtkqew2adsjhfg")
    static let GENERATOR: [UInt] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]

    public static func getAddress(from publicKey: String) -> String {
        return getBinaryAddress(from: publicKey).hexString()
    }

    public static func getBase32Address(from publicKey: String) -> String {
        let binaryAddress = getBinaryAddress(from: publicKey)
        let uint5Address = convertUIntArray(binaryAddress.map { UInt($0) }, 8, 5)
        let uint5Checksum = createChecksum(uint5Address)
        let identifier = convertUInt5ToBase32(uint5Address + uint5Checksum)
        return "\(PREFIX_LISK)\(identifier)"
    }

    public static func getBinaryAddressFromBase32(_ base32Address: String) -> String? {
        guard isValidBase32(address: base32Address) else { return nil }

        let addressArray = Array(base32Address)[PREFIX_LISK.count..<(base32Address.count - 6)]
        let integerSequence = addressArray.compactMap { CHARSET.firstIndex(of: $0) }.map { UInt($0) }

        guard integerSequence.count == 32 else { return nil }

        return convertUIntArray(integerSequence, 5, 8).map { UInt8($0) }.hexString()
    }

    public static func isValidBase32(address: String) -> Bool {
        guard address.prefix(3) == "lsk", address.count == 41 else { return false }

        let content = String(address.suffix(38))
        let bytes = covertBase32toUInt5(content)
        let address = Array(bytes[0..<32])
        let checksum = Array(bytes[32..<38])

        guard createChecksum(address) == checksum else { return false }

        return true
    }
    
    internal static func getBinaryAddress(from publicKey: String) -> [UInt8] {
        let bytes = SHA256(publicKey.hexBytes()).digest()[0..<20]
        return Array(bytes)
    }

    internal static func convertUIntArray(_ array: [UInt], _ from: UInt, _ to: UInt) -> [UInt] {
        let maxValue: UInt = (1 << to) - 1
        var accumulator: UInt = 0
        var bits: UInt = 0
        var result = [UInt]()
        for byte in array {
            accumulator = (accumulator << from) | byte
            bits += from
            while (bits >= to) {
                bits -= to
                result.append((accumulator >> bits) & maxValue)
            }
        }
        return result
    }

    internal static func createChecksum(_ array: [UInt]) -> [UInt] {
        let values = array + [0, 0, 0, 0, 0, 0]
        let mod: UInt = polymod(values) ^ 1
        var result = [UInt]()
        for p: UInt in 0..<6 {
            result.append((mod >> (5 * (5 - p))) & 31)
        }
        return result
    }

    internal static func polymod(_ array: [UInt]) -> UInt {
        var chk: UInt = 1
        for value in array {
            let top: UInt = chk >> 25
            chk = ((chk & 0x1ffffff) << 5) ^ value
            for i: UInt8 in 0..<6 {
                if (((top >> i) & 1) != 0) {
                    chk ^= GENERATOR[Int(i)]
                }
            }
        }
        return chk
    }

    internal static func convertUInt5ToBase32(_ array: [UInt]) -> String {
        return array.map { String(CHARSET[Int($0)]) }.joined()
    }
    
    internal static func covertBase32toUInt5(_ value:String) -> [UInt] {
        return value.enumerated().map { UInt(CHARSET.firstIndex(of: Character(String($0.element))) ?? 0) }
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

    public static func verify(message: [UInt8], signature: [UInt8], publicKey: [UInt8]) throws -> Bool {
        guard signature.count == 64 else {
            throw CryptoError.invalidSignatureLength
        }
        
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

    public static func fixedPoint(amount: Decimal) -> UInt64 {
        return NSDecimalNumber(decimal: amount * Constants.fixedPointDecimal).uint64Value
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
    internal func allHexBytes() -> [UInt8] {
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
        
        guard .SUCCESS == crypto_sign_detached(
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
