//
//  StateType.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25.05.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public enum StateType: Equatable, Hashable, Sendable {
    case unknown(raw: Int)
    case keyValue // 0
    
    public var rawValue: Int {
        switch self {
        case .keyValue: return 0
        case .unknown(let raw): return raw
        }
    }
}

extension StateType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let type = try container.decode(Int.self)
        self = type.toStateType()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}

private extension Int {
    func toStateType() -> StateType {
        switch self {
        case 0: return .keyValue
            
        default: return .unknown(raw: self)
        }
    }
}
