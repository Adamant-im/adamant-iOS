import Foundation

final class Base58AddressConverter: AddressConverter {
    private static let checkSumLength = 4
    private let addressVersion: UInt8
    private let addressScriptVersion: UInt8

    init(addressVersion: UInt8, addressScriptVersion: UInt8) {
        self.addressVersion = addressVersion
        self.addressScriptVersion = addressScriptVersion
    }

    func convert(address: String) throws -> Address {
        // check length of address to avoid wrong converting
        guard address.count >= 26 && address.count <= 35 else {
            throw BitcoinError.invalidAddressLength
        }

        guard let hex = Base58.decode(address) else {
            throw BitcoinError.unknownAddressType
        }
        
        // check decoded length. Must be 1(version) + 20(KeyHash) + 4(CheckSum)
        if hex.count != Base58AddressConverter.checkSumLength + 20 + 1 {
            throw BitcoinError.invalidAddressLength
        }
        let givenChecksum = hex.suffix(Base58AddressConverter.checkSumLength)
        let doubleSHA256 = Crypto.sha256sha256(hex.prefix(hex.count - Base58AddressConverter.checkSumLength))
        let actualChecksum = doubleSHA256.prefix(Base58AddressConverter.checkSumLength)
        guard givenChecksum == actualChecksum else {
            throw BitcoinError.invalidChecksum
        }

        let type: AddressType
        switch hex[0] {
            case addressVersion: type = AddressType.pubkeyHash
            case addressScriptVersion: type = AddressType.scriptHash
            default: throw BitcoinError.wrongAddressPrefix
        }

        let keyHash = hex.dropFirst().dropLast(4)
        return LegacyAddress(type: type, payload: keyHash, base58: address)
    }

    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address {
        let version: UInt8
        let addressType: AddressType

        switch type {
            case .p2pkh, .p2pk:
                version = addressVersion
                addressType = AddressType.pubkeyHash
            case .p2sh, .p2wpkhSh:
                version = addressScriptVersion
                addressType = AddressType.scriptHash
            default: throw BitcoinError.unknownAddressType
        }

        var withVersion = (Data([version])) + lockingScriptPayload
        let doubleSHA256 = Crypto.sha256sha256(withVersion)
        let checksum = doubleSHA256.prefix(4)
        withVersion += checksum
        let base58 = Base58.encode(withVersion)
        return LegacyAddress(type: addressType, payload: lockingScriptPayload, base58: base58)
    }
    
    func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
        let keyHash = type == .p2wpkhSh ? publicKey.hashP2wpkhWrappedInP2sh : publicKey.hashP2pkh
        return try convert(lockingScriptPayload: keyHash, type: type)
    }
}
