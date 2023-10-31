//
//  AdamantCore+Extensions.swift
//  Adamant
//
//  Created by Andrey Golubenko on 25.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit
import BigInt

extension AdamantCore {
    func makeSignedTransaction(
        transaction: SignableTransaction,
        senderId: String,
        keypair: Keypair
    ) -> UnregisteredTransaction? {
        guard let signature = sign(transaction: transaction, senderId: senderId, keypair: keypair) else {
            return nil
        }
        
        return .init(
            type: transaction.type,
            timestamp: transaction.timestamp,
            senderPublicKey: transaction.senderPublicKey,
            senderId: senderId,
            recipientId: transaction.recipientId,
            amount: transaction.amount,
            signature: signature,
            asset: transaction.asset,
            requesterPublicKey: transaction.requesterPublicKey
        )
    }
}

// MARK: - Bytes

extension UnregisteredTransaction {
    var id: String {
        generateId()
    }
}

private extension UnregisteredTransaction {
    func generateId() -> String {
        let hash = bytes.sha256()
        
        guard hash.count > 7 else { return UUID().uuidString }
        
        var temp: [UInt8] = []
        
        for i in 0..<8 {
            temp.insert(hash[7 - i], at: i)
        }
        
        guard let value = bigIntFromBuffer(temp, size: 1) else {
            return UUID().uuidString
        }
        
        return String(value)
    }
    
    func bigIntFromBuffer(_ buffer: [UInt8], size: Int) -> BigInt? {
        if buffer.isEmpty || size <= 0 {
            return nil
        }
        
        var chunks: [[UInt8]] = []
        
        for i in stride(from: 0, to: buffer.count, by: size) {
            let chunk = buffer[i]
            chunks.append([chunk])
        }
        
        let hexStrings = chunks.map { chunk in
            return chunk.map { byte in
                let hex = String(byte, radix: 16)
                return hex.count == 1 ? "0" + hex : hex
            }.joined()
        }
        
        let hex = hexStrings.joined()
        
        return BigInt(hex, radix: 16)
    }
    
    var bytes: [UInt8] {
        return typeBytes
        + timestampBytes
        + senderPublicKeyBytes
        + requesterPublicKeyBytes
        + recipientIdBytes
        + amountBytes
        + assetBytes
        + signatureBytes
        + signSignatureBytes
    }
    
    var typeBytes: [UInt8] {
        [UInt8(type.rawValue)]
    }
    
    var timestampBytes: [UInt8] {
        ByteBackpacker.pack(UInt32(timestamp), byteOrder: .littleEndian)
    }
    
    var senderPublicKeyBytes: [UInt8] {
        senderPublicKey.hexBytes()
    }
    
    var requesterPublicKeyBytes: [UInt8] {
        requesterPublicKey?.hexBytes() ?? []
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
        signature.hexBytes()
    }
    
    var signSignatureBytes: [UInt8] {
        []
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
