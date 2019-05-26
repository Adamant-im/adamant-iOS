//
//  DashRawTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

class DashTransaction: BaseBtcTransaction {
    override class var defaultCurrencySymbol: String? { return DashWalletService.currencySymbol }
}

struct BtcBlock: Decodable {
    let hash: String
    let height: Int64
    let time: Int64
    
    enum CodingKeys: String, CodingKey {
        case hash
        case height
        case time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.hash = try container.decode(String.self, forKey: .hash)
        self.height = try container.decode(Int64.self, forKey: .height)
        self.time = try container.decode(Int64.self, forKey: .time)
    }
}

struct DashUnspentTransaction: Decodable {
    let address: String
    let txid: String
    let outputIndex: UInt32
    let script: String
    let amount: UInt64
    let height: UInt64
    
    enum CodingKeys: String, CodingKey {
        case address
        case txid
        case outputIndex
        case script
        case amount = "satoshis"
        case height
    }
    
    func asUnspentTransaction(with publicKeyHash: Data) -> UnspentTransaction {
        let lockScript = Script.buildPublicKeyHashOut(pubKeyHash: publicKeyHash)
        let txHash = Data(hex: txid).map { Data($0.reversed()) } ?? Data()
        
        let unspentOutput = TransactionOutput(value: amount, lockingScript: lockScript)
        let unspentOutpoint = TransactionOutPoint(hash: txHash, index: outputIndex)
        let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)
        return utxo
    }
}

//{
//    "address": "Xp6kFbogHMD4QRBDLQdqRp5zUgzmfj1KPn",
//    "txid": "4270bdbdcf89c0a39fd3e81f8b8bd991507d66c643703a007f8f6b466504de83",
//    "outputIndex": 0,
//    "script": "76a914931ef5cbdad28723ba9596de5da1145ae969a71888ac",
//    "satoshis": 3000000,
//    "height": 1009632
//}
