//
//  AddressConverter.swift
//  BitcoinKit
//
//  Created by Anton Boyarkin on 12/02/2019.
//

import Foundation

class AddressConverter {
    enum ConversionError: Error {
        case invalidChecksum
        case invalidAddressLength
        case unknownAddressType
        case wrongAddressPrefix
    }
    
    
    public static func extract(from signatureScript: Data, with network: Network) -> Address? {
        var payload: Data?
        var validScriptType: ScriptType = ScriptType.unknown
        let sigScriptCount = signatureScript.count
        
        var outputAddress: Address?
        
        if let script = Script(data: signatureScript), // PFromSH input {push-sig}{signature}{push-redeem}{script}
            let chunkData = script.chunks.last?.scriptData,
            let redeemScript = Script(data: chunkData),
            let opCode = redeemScript.chunks.last?.opCode.value {
            // parse PFromSH transaction input
            var verifyChunkCode: UInt8 = opCode
            if verifyChunkCode == OpCode.OP_ENDIF,
                redeemScript.chunks.count > 1,
                let opCode = redeemScript.chunks.suffix(2).first?.opCode {
                
                verifyChunkCode = opCode.value    // check pre-last chunk
            }
            if OpCode.pFromShCodes.contains(verifyChunkCode) {
                payload = chunkData                                     //full script
                validScriptType = .p2sh
            }
        }
        
        if payload == nil, sigScriptCount >= 106, signatureScript[0] >= 71, signatureScript[0] <= 74 {
            // parse PFromPKH transaction input
            let signatureOffset = signatureScript[0]
            let pubKeyLength = signatureScript[Int(signatureOffset + 1)]
            
            if (pubKeyLength == 33 || pubKeyLength == 65) && sigScriptCount == signatureOffset + pubKeyLength + 2 {
                payload = signatureScript.subdata(in: Int(signatureOffset + 2)..<sigScriptCount)    // public key
                validScriptType = .p2pkh
            }
        }
        if payload == nil, sigScriptCount == ScriptType.p2wpkhSh.size,
            signatureScript[0] == 0x16,
            (signatureScript[1] == 0 || (signatureScript[1] > 0x50 && signatureScript[1] < 0x61)),
            signatureScript[2] == 0x14 {
            // parse PFromWPKH-SH transaction input
            payload = signatureScript.subdata(in: 1..<sigScriptCount)      // 0014{20-byte-key-hash}
            validScriptType = .p2wpkhSh
        }
        if let payload = payload {
            let keyHash = Crypto.sha256ripemd160(payload)
            if let address = try? network.convert(keyHash: keyHash, type: validScriptType) {
                outputAddress = address
            }
        }
        return outputAddress
    }
}
