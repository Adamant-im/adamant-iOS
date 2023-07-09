//
//  LegacyAddress.swift
//
//  Copyright © 2018 Kishikawa Katsumi
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public final class LegacyAddress: Address, Equatable {
    public let type: AddressType
    public let lockingScriptPayload: Data
    public let stringValue: String

    public var scriptType: ScriptType {
        switch type {
            case .pubkeyHash: return .p2pkh
            case .scriptHash: return .p2sh
        }
    }
    
    public var qrcodeString: String {
        stringValue
    }
    
    public var lockingScript: Data {
        switch type {
        case .pubkeyHash: return OpCode.p2pkhStart + OpCode.push(lockingScriptPayload) + OpCode.p2pkhFinish
        case .scriptHash: return OpCode.p2shStart + OpCode.push(lockingScriptPayload) + OpCode.p2shFinish
        }
    }

    public init(type: AddressType, payload: Data, base58: String) {
        self.type = type
        self.lockingScriptPayload = payload
        self.stringValue = base58
    }

    public static func ==<T: Address>(lhs: LegacyAddress, rhs: T) -> Bool {
        guard let rhs = rhs as? LegacyAddress else {
            return false
        }
        return lhs.type == rhs.type && lhs.lockingScriptPayload == rhs.lockingScriptPayload
    }
}
