//
//  AtomicObservableValue.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

import Foundation
import Combine

@propertyWrapper
public final class AtomicObservableValue<Element: Sendable>: Sendable {
    private let currentValue: ActorBox<Element>
    private let subscription: ActorBox<AnyCancellable?>
    private let core: SendableObservableValue<Element>
    
    public var projectedValue: AtomicObservableValue<Element> { self }
    
    public var wrappedValue: Element {
        get { value }
        set { value = newValue }
    }
    
    public var value: Element {
        get { Task.sync { [currentValue] in await currentValue.value } }
        set { Task.sync { [core] in await core.send(newValue) } }
    }
    
    public init(_ value: Element) {
        currentValue = .init(value)
        subscription = .init(nil)
        core = .init(.init(value))
        Task { await configure() }
    }
    
    public convenience init(wrappedValue: Element) {
        self.init(wrappedValue)
    }
    
    @discardableResult
    public func mutate<T: Sendable>(
        _ mutation: @Sendable @escaping (inout Element) -> T
    ) -> T {
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

private extension AtomicObservableValue {
    func configure() async {
        await subscription.isolated { [core, currentValue] subscription in
            subscription.value = Task {
                for try await value in core.makeSequence() {
                    await currentValue.isolated { $0.value = value }
                }
            }.eraseToAnyCancellable()
        }
    }
}
