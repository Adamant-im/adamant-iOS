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
