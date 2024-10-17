//
//  AtomicObservableValue.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

import Foundation

@propertyWrapper
public final class AtomicObservableValue<Element: Sendable>: Sendable {
    public let core: SendableObservableValue<Element>
    
    public var projectedValue: AtomicObservableValue<Element> { self }
    
    public var wrappedValue: Element {
        get { value }
        set { value = newValue }
    }
    
    /// Avoid using it. Use the async version from the `core` property.
    public var value: Element {
        get { Task.sync { [core] in await core.value } }
        set { Task.sync { [core] in await core.send(newValue) } }
    }
    
    public init(_ value: Element) {
        core = .init(.init(value))
    }
    
    public convenience init(wrappedValue: Element) {
        self.init(wrappedValue)
    }
    
    /// Avoid using it. Use the async version from the `core` property.
    @discardableResult
    public func mutate<T: Sendable>(_ mutation: @Sendable @escaping (inout Element) -> T) -> T {
        Task.sync { [core] in
            await core.isolated { core in
                mutation(&core.publisher.value)
            }
        }
    }
}

extension AtomicObservableValue: AsyncStreamable {
    public func makeSequence() -> SendableObservableValue<Element>.ProducedSequence {
        core.makeSequence()
    }
}
