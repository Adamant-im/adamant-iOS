//
//  ScriptType.swift
//  BitcoinKit
//
//  Created by Anton Boyarkin on 12/02/2019.
//

import Foundation

public enum ScriptType: Int {
    case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh
    
    var size: Int {
        switch self {
        case .p2pk: return 35
        case .p2pkh: return 25
        case .p2sh: return 23
        case .p2wsh: return 34
        case .p2wpkh: return 22
        case .p2wpkhSh: return 23
        default: return 0
        }
    }
    
    var keyLength: UInt8 {
        switch self {
        case .p2pk: return 0x21
        case .p2pkh: return 0x14
        case .p2sh: return 0x14
        case .p2wsh: return 0x20
        case .p2wpkh: return 0x14
        case .p2wpkhSh: return 0x14
        default: return 0
        }
    }
    
    var addressType: AddressType {
        switch self {
        case .p2sh, .p2wsh: return .scriptHash
        default: return .pubkeyHash
        }
    }
    
    var witness: Bool {
        return self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh
    }
    
}
