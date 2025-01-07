//
//  CoinHealthCheckParameters.swift
//  
//
//  Created by Stanislav Jelezoglo on 28.12.2023.
//

import Foundation

public struct CoinHealthCheckParameters {
    public let normalUpdateInterval: TimeInterval
    public let crucialUpdateInterval: TimeInterval
    public let onScreenUpdateInterval: TimeInterval
    public let threshold: Int
    public let normalServiceUpdateInterval: TimeInterval
    public let crucialServiceUpdateInterval: TimeInterval
    public let onScreenServiceUpdateInterval: TimeInterval
    
    public init(
        normalUpdateInterval: TimeInterval,
        crucialUpdateInterval: TimeInterval,
        onScreenUpdateInterval: TimeInterval,
        threshold: Int,
        normalServiceUpdateInterval: TimeInterval,
        crucialServiceUpdateInterval: TimeInterval,
        onScreenServiceUpdateInterval: TimeInterval
    ) {
        self.normalUpdateInterval = normalUpdateInterval
        self.crucialUpdateInterval = crucialUpdateInterval
        self.onScreenUpdateInterval = onScreenUpdateInterval
        self.threshold = threshold
        self.normalServiceUpdateInterval = normalServiceUpdateInterval
        self.crucialServiceUpdateInterval = crucialServiceUpdateInterval
        self.onScreenServiceUpdateInterval = onScreenServiceUpdateInterval
    }
}
extension CoinHealthCheckParameters: Decodable {
    private enum CodingKeys: String, CodingKey {
        case normalUpdateInterval
        case crucialUpdateInterval
        case onScreenUpdateInterval
        case threshold
        case normalServiceUpdateInterval
        case crucialServiceUpdateInterval
        case onScreenServiceUpdateInterval
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        normalUpdateInterval = try container.decode(TimeInterval.self, forKey: .normalUpdateInterval)
        crucialUpdateInterval = try container.decode(TimeInterval.self, forKey: .crucialUpdateInterval)
        onScreenUpdateInterval = try container.decode(TimeInterval.self, forKey: .onScreenUpdateInterval)
        threshold = try container.decode(Int.self, forKey: .threshold)
        normalServiceUpdateInterval = try container.decode(TimeInterval.self, forKey: .normalServiceUpdateInterval)
        crucialServiceUpdateInterval = try container.decode(TimeInterval.self, forKey: .crucialServiceUpdateInterval)
        onScreenServiceUpdateInterval = try container.decode(TimeInterval.self, forKey: .onScreenServiceUpdateInterval)
    }
}
