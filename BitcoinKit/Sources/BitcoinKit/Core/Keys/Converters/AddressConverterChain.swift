import Foundation

final class AddressConverterChain: AddressConverter {
    private let concreteConverters: [AddressConverter]
    
    init(concreteConverters: [AddressConverter]) {
        self.concreteConverters = concreteConverters
    }

    func convert(address: String) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                let converted = try converter.convert(address: address)
                return converted
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinError.list(errors: errors)
    }

    func convert(lockingScriptPayload: Data, type: ScriptType) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                let converted = try converter.convert(lockingScriptPayload: lockingScriptPayload, type: type)
                return converted
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinError.list(errors: errors)
    }
    
    public func convert(publicKey: PublicKey, type: ScriptType) throws -> Address {
        var errors = [Error]()

        for converter in concreteConverters {
            do {
                let converted = try converter.convert(publicKey: publicKey, type: type)
                return converted
            } catch {
                errors.append(error)
            }
        }

        throw BitcoinError.list(errors: errors)
    }
}
