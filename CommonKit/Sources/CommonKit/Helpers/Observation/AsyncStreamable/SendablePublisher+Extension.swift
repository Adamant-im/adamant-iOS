//
//  SendablePublisher+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

import Combine

extension SendablePublisher where P: Subject {
    public func send(_ value: Element) {
        publisher.send(value)
    }

    public func send(completion: Subscribers.Completion<P.Failure>) {
        publisher.send(completion: completion)
    }
}

extension SendableObservableValue where P: ValueSubject {
    public var value: Element {
        get { publisher.value }
        set { publisher.value = newValue }
    }
}
