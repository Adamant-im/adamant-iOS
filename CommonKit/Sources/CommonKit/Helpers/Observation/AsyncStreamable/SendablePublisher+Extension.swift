//
//  SendablePublisher+Extension.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

import Combine

public extension SendablePublisher where P: Subject {
    func send(_ value: Element) {
        publisher.send(value)
    }
    
    func send(completion: Subscribers.Completion<P.Failure>) {
        publisher.send(completion: completion)
    }
}

public extension SendableObservableValue where P: ValueSubject {
    var value: Element {
        get { publisher.value }
        set { publisher.value = newValue }
    }
}
