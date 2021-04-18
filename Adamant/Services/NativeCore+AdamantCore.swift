//
//  NativeCore+AdamantCore.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import CryptoSwift

extension NativeAdamantCore: AdamantCore {
    // MARK: - Passphrases
    
    func generateNewPassphrase() -> String {
        if let passphrase = try? Mnemonic.generate().joined(separator: " ") {
            return passphrase
        }
        return ""
    }
    
    
    // MARK: - Signing transactions
    
    func sign(transaction: SignableTransaction, senderId: String, keypair: Keypair) -> String? {
        let privateKey = keypair.privateKey.hexBytes()
        let hash = transaction.bytes.sha256()
        
        guard let signature = Crypto.sign.signature(message: hash, secretKey: privateKey) else {
            print("FAIL to sign of transaction")
            return nil
        }
        
        return signature.hexString()
    }
}

// MARK: - Bytes
fileprivate extension SignableTransaction {
    
    var bytes: [UInt8] {
        return
            typeBytes +
                timestampBytes +
                senderPublicKeyBytes +
                requesterPublicKeyBytes +
                recipientIdBytes +
                amountBytes +
                assetBytes +
                signatureBytes +
        signSignatureBytes
    }
    
    var typeBytes: [UInt8] {
        return [UInt8(type.rawValue)]
    }
    
    var timestampBytes: [UInt8] {
        return ByteBackpacker.pack(UInt32(timestamp), byteOrder: .littleEndian)
    }
    
    var senderPublicKeyBytes: [UInt8] {
        return senderPublicKey.hexBytes()
    }
    
    var requesterPublicKeyBytes: [UInt8] {
        return requesterPublicKey?.hexBytes() ?? []
    }
    
    var recipientIdBytes: [UInt8] {
        guard
            let value = recipientId?.replacingOccurrences(of: "U", with: ""),
            let number = UInt64(value) else { return Bytes(count: 8) }
        return ByteBackpacker.pack(number, byteOrder: .bigEndian)
    }
    
    var amountBytes: [UInt8] {
        let value = (self.amount.shiftedToAdamant() as NSDecimalNumber).uint64Value
        let bytes = ByteBackpacker.pack(value, byteOrder: .littleEndian)
        return bytes
    }
    
    var signatureBytes: [UInt8] {
        return []
    }
    
    var signSignatureBytes: [UInt8] {
        return []
    }
    
    var assetBytes: [UInt8] {
        switch type {
        case .chatMessage:
            guard let msg = asset.chat?.message, let own = asset.chat?.ownMessage, let type = asset.chat?.type else { return [] }
            
            return msg.hexBytes() + own.hexBytes() + ByteBackpacker.pack(UInt32(type.rawValue), byteOrder: .littleEndian)
            
        case .state:
            guard let key = asset.state?.key, let value = asset.state?.value, let type = asset.state?.type else { return [] }
            
            return value.bytes + key.bytes + ByteBackpacker.pack(UInt32(type.rawValue), byteOrder: .littleEndian)
            
        case .vote:
            guard
                let votes = asset.votes?.votes
                else { return [] }
            
            var bytes = [UInt8]()
            for vote in votes {
                bytes += vote.bytes
            }
            
            return bytes
            
        default:
            return []
        }
    }
}
