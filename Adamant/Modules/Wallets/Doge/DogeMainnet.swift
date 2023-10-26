//
//  DogeMainnet.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import BitcoinKit

final class DogeMainnet: Network {
    override var name: String {
        return "livenet"
    }
    
    override var alias: String {
        return "mainnet"
    }
    
    override var scheme: String {
        return "dogecoin"
    }
    
    override var magic: UInt32 {
        return 0xc0c0c0c0
    }
    
    override var pubkeyhash: UInt8 {
        return 0x1e
    }
    
    override var privatekey: UInt8 {
        return 0x9e
    }
    
    override var scripthash: UInt8 {
        return 0x16
    }
    
    override var xpubkey: UInt32 {
        return 0x02facafd
    }
    
    override var xprivkey: UInt32 {
        return 0x02fac398
    }
    
    override var port: UInt32 {
        return 22556
    }
    
    override var dnsSeeds: [String] {
        return [
            "dogenode1.adamant.im"
        ]
    }
}
