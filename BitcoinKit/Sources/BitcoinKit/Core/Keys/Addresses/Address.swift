//
//  Address.swift
//  
//
//  Created by Andrey Golubenko on 05.06.2023.
//

import Foundation

public protocol AddressProtocol {
    var scriptType: ScriptType { get }
    var lockingScriptPayload: Data { get }
    var stringValue: String { get }
    var lockingScript: Data { get }
}

#if os(iOS) || os(tvOS) || os(watchOS)
public typealias Address = AddressProtocol & QRCodeConvertible
#else
public typealias Address = AddressProtocol
#endif
