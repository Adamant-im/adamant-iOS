//
//  JSAdamantCore+Native.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import libsodium

extension JSAdamantCore {
    func decodeValue(rawMessage: String, rawNonce: String, privateKey privateKeyHex: String) -> String? {
        let message = rawMessage.hexBytes()
        let nonce = rawNonce.hexBytes()
        let privateKey = privateKeyHex.hexBytes()
        
        guard let hash = hashSHA256(privateKey: privateKey) else {
            print("FAIL to create SHA256 of private key")
            return nil
        }
        
        guard let secretKey = ed2curve(privateKey: hash) else {
            print("FAIL to create ed2curve secret key from SHA256")
            return nil
        }
        
        guard let decrepted = open(authenticatedCipherText: message, secretKey: secretKey, nonce: nonce) else {
            print("FAIL to decrypt")
            return nil
        }
        
        return decrepted.utf8String
    }
    
    private func open(authenticatedCipherText: Bytes, secretKey: Bytes, nonce: Bytes) -> Bytes? {
        guard authenticatedCipherText.count >= MacBytes else { return nil }
        var message = Bytes(count: authenticatedCipherText.count - MacBytes)
        
        guard .SUCCESS == crypto_secretbox_open_easy (
            &message,
            authenticatedCipherText, UInt64(authenticatedCipherText.count),
            nonce,
            secretKey
            ).exitCode else { return nil }
        
        return message
    }
    
    private func hashSHA256(privateKey: Bytes) -> Bytes? {
        var hash = Bytes(count: HashSHA256Bytes)
        
        guard .SUCCESS == crypto_hash_sha256(
            &hash,
            privateKey, UInt64(privateKey.count)
            ).exitCode else { return nil }
        
        return hash
    }
    
    private func ed2curve(privateKey: Bytes) -> Bytes? {
        var secretKey = Bytes(count: SecretKeyBytes)
        
        guard .SUCCESS == crypto_sign_ed25519_sk_to_curve25519(
            &secretKey,
            privateKey
            ).exitCode else { return nil }
        
        return secretKey
    }
}

// MARK:- Helpers
public let HashSHA256Bytes = Int(crypto_hash_sha256_bytes())
public let SecretKeyBytes = Int(crypto_scalarmult_curve25519_bytes())
public let MacBytes = Int(crypto_secretbox_macbytes())

public typealias Bytes = Array<UInt8>

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension Array where Element == UInt8 {
    init (count bytes: Int) {
        self.init(repeating: 0, count: bytes)
    }
    
    public var utf8String: String? {
        return String(data: Data(bytes: self), encoding: .utf8)
    }
    
    func toData() -> Data {
        return Data(bytes: self)
    }
}

extension ArraySlice where Element == UInt8 {
    var bytes: Bytes { return Bytes(self) }
}

extension String {
    var bytes: Bytes { return Bytes(self.utf8) }
    
    func hexBytes() -> [UInt8] {
        return (0..<count/2).reduce([]) { res, i in
            let indexStart = index(startIndex, offsetBy: i * 2)
            let indexEnd = index(indexStart, offsetBy: 2)
            let substring = self[indexStart..<indexEnd]
            return res + [UInt8(substring, radix: 16) ?? 0]
        }
    }
    
    func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self,
                                        range: NSRange(self.startIndex..., in: self))
            return results.map {
                String(self[Range($0.range, in: self)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
}

enum ExitCode {
    case SUCCESS
    case FAILURE
    
    init (from int: Int32) {
        switch int {
        case 0:  self = .SUCCESS
        default: self = .FAILURE
        }
    }
}

extension Int32 {
    var exitCode: ExitCode { return ExitCode(from: self) }
}

extension Sequence where Self.Element == UInt8 {
    internal func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
