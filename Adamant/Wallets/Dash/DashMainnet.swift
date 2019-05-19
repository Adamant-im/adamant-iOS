//
//  DashMainnet.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

class DashMainnet: Network {
    override var name: String {
        return "livenet"
    }
    
    override var alias: String {
        return "mainnet"
    }
    
    override var scheme: String {
        return "dash"
    }
    
    override var magic: UInt32 {
        return 0xbd6b0cbf
    }
    
    override var pubkeyhash: UInt8 {
        return 0x4c
    }
    
    override var privatekey: UInt8 {
        return 0x4c
    }
    
    override var scripthash: UInt8 {
        return 0x10
    }
    
    override var xpubkey: UInt32 {
        return 0x0488b21e
    }
    
    override var xprivkey: UInt32 {
        return 0x0488ade4
    }
    
    override var port: UInt32 {
        return 9999
    }
    
    override var dnsSeeds: [String] {
        return [
            "dashnode1.adamant.im"
        ]
    }
}
