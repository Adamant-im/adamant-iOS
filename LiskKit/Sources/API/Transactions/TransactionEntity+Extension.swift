//
//  TransactionEntity+Extension.swift
//
//
//  Created by Stanislav Jelezoglo on 18.12.2023.
//

import Foundation

public extension TransactionEntity {
    var id: String {
        getTxID() ?? ""
    }
    
    var recipientAddressBase32: String {
        let bytes = [UInt8](params.recipientAddressBinary)
        let binary = bytes.hexString()
        return Crypto.getBase32Address(binaryAddress: binary)
    }
    
    var senderAddress: String {
        let bytes = [UInt8](senderPublicKey)
        let senderPublicKey = bytes.hexString()
        return Crypto.getBase32Address(from: senderPublicKey)
    }
    
    func createTx(
        amount: Decimal,
        fee: Decimal,
        nonce: UInt64,
        senderPublicKey: String,
        recipientAddressBinary: String
    ) -> TransactionEntity {
        let amount = Crypto.fixedPoint(amount: amount)
        let fee = Crypto.fixedPoint(amount: fee)
        
        return TransactionEntity.with {
            $0.command = Constants.command
            $0.module = Constants.module
            $0.fee = fee
            $0.nonce = nonce
            $0.senderPublicKey = Data(senderPublicKey.allHexBytes())
            $0.params = TransactionEntity.Params.with {
                $0.tokenID = Data(Constants.tokenID.allHexBytes())
                $0.amount = amount
                $0.recipientAddressBinary = Data(recipientAddressBinary.allHexBytes())
                $0.data = ""
            }
            $0.signatures = []
        }
    }
    
    func sign(with keyPair: KeyPair, for chainID: String) -> TransactionEntity {
        let signature = signature(with: keyPair, for: chainID)
        
        return TransactionEntity.with {
            $0.command = command
            $0.module = module
            $0.fee = fee
            $0.nonce = nonce
            $0.senderPublicKey = senderPublicKey
            $0.params = params
            $0.signatures = [Data(signature.allHexBytes())]
        }
    }
    
    func getTxHash() -> String? {
        let bytes = try? serializedData()
        return bytes?.hexString()
    }
    
    func getTxID() -> String? {
        let bytes = try? serializedData()
        return bytes?.sha256().hexString()
    }
    
    func getFee(with minFeePerByte: UInt64) -> UInt64 {
        let bytesCount = (try? serializedData().count) ?? .zero
        return UInt64(bytesCount) * minFeePerByte
    }
}

private extension TransactionEntity {
    func signature(with keyPair: KeyPair, for chainID: String) -> String {
        let unsignedBytes = (try? serializedData()) ?? Data()
        
        guard !unsignedBytes.isEmpty else {
            return ""
        }
        
        let tagBytes: [UInt8] = Array("LSK_TX_".utf8)
        let chainBytes: [UInt8] = chainID.allHexBytes()
        let allBytes = tagBytes
        + chainBytes
        + unsignedBytes
              
        let sha = allBytes.sha256()
        let signBytes = Ed25519.sign(message: sha, privateKey: keyPair.privateKey)
        let sign = signBytes.hexString()
        
        return sign
    }
}
