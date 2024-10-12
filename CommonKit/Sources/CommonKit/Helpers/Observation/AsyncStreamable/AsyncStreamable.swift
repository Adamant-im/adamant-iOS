//
//  AsyncStreamable.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation

public protocol AsyncStreamable: Sendable {
    associatedtype Element: Sendable
    associatedtype ProducedSequence: AsyncSequence where ProducedSequence.Element == Element
    
    func makeSequence() -> ProducedSequence
}
