//
//  ScriptType.swift
//  BitcoinKit
//
//  Created by Anton Boyarkin on 12/02/2019.
//

import Foundation

public enum ScriptType: Int {
    case unknown, p2pkh, p2pk, p2multi, p2sh, p2wsh, p2wpkh, p2wpkhSh, p2tr
    
    var size: Int {
        switch self {
        case .p2pk: return 35
        case .p2pkh: return 25
        case .p2sh: return 23
        case .p2wsh: return 34
        case .p2wpkh: return 22
        case .p2wpkhSh: return 23
        case .p2tr: return 34
        case .unknown, .p2multi: return .zero
        }
    }
    
    var witness: Bool {
        self == .p2wpkh || self == .p2wpkhSh || self == .p2wsh || self == .p2tr
    }
}
