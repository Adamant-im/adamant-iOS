import Foundation

public final class SegWitV0Address: Address, Equatable {
    public let type: AddressType
    public let lockingScriptPayload: Data
    public let stringValue: String
    
    public var qrcodeString: String {
        stringValue
    }

    public var scriptType: ScriptType {
        switch type {
        case .pubkeyHash: return .p2wpkh
        case .scriptHash: return .p2wsh
        }
    }

    public var lockingScript: Data {
        OpCode.segWitOutputScript(lockingScriptPayload, versionByte: 0)
    }

    public init(type: AddressType, payload: Data, bech32: String) {
        self.type = type
        self.lockingScriptPayload = payload
        self.stringValue = bech32
    }

    static public func ==<T: Address>(lhs: SegWitV0Address, rhs: T) -> Bool {
        guard let rhs = rhs as? SegWitV0Address else {
            return false
        }
        return lhs.type == rhs.type && lhs.lockingScriptPayload == rhs.lockingScriptPayload
    }
}
