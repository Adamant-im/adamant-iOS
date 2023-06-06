//
//  AddressConverterFactory.swift
//  
//
//  Created by Andrey Golubenko on 06.06.2023.
//

public struct AddressConverterFactory {
    public func make(network: Network) -> AddressConverter {
        let segWitAddressConverter = SegWitBech32AddressConverter(prefix: "bc")
        
        let base58AddressConverter = Base58AddressConverter(
            addressVersion: network.pubkeyhash,
            addressScriptVersion: network.scripthash
        )
        
        return AddressConverterChain(concreteConverters: [
            segWitAddressConverter,
            base58AddressConverter
        ])
    }
    
    public init() {}
}
