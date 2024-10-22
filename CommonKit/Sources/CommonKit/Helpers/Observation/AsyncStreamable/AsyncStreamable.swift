//
//  AsyncStreamable.swift
//  CommonKit
//
//  Created by Andrew G on 12.10.2024.
//

import Foundation

public protocol AsyncStreamable<Element>: Sendable {
    associatedtype Element: Sendable
    associatedtype ProducedSequence: AsyncSequence & Sendable where ProducedSequence.Element == Element
    
    func makeSequence() -> ProducedSequence
}
