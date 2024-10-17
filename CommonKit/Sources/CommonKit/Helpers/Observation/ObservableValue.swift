//
//  ObservableValue.swift
//  Adamant
//
//  Created by Andrey Golubenko on 24.01.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Combine

/// `Published` changes its `wrappedValue` after calling `sink` or `assign`.
/// But `ObservableValue` does it before.
@propertyWrapper public final class ObservableValue<Output>: Publisher {
    public typealias Output = Output
    public typealias Failure = Never
    
    private let subject: CurrentValueSubject<Output, Failure>

    public var wrappedValue: Output {
        get { value }
        set { value = newValue }
    }
    
    public var projectedValue: some Observable<Output> {
        subject
    }
    
    public init(_ value: Output) {
        subject = .init(value)
    }

    public convenience init(wrappedValue: Output) {
        self.init(wrappedValue)
    }
}

extension ObservableValue: ValueSubject {
    public var value: Output {
        get { subject.value }
        set { subject.value = newValue }
    }
    
    public func send(_ value: Output) {
        subject.send(value)
    }
    
    public func send(completion: Subscribers.Completion<Never>) {
        subject.send(completion: completion)
    }
    
    public func send(subscription: any Subscription) {
        subject.send(subscription: subscription)
    }
    
    public func receive<S>(
        subscriber: S
    ) where S: Subscriber, Never == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
}

public extension Publisher where Failure == Never {
    func assign(to observableValue: ObservableValue<Output>) -> AnyCancellable {
        assign(to: \.wrappedValue, on: observableValue)
    }
}
