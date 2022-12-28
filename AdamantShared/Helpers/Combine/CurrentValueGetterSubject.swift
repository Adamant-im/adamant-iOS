//
//  CurrentValueGetterSubject.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine

struct CurrentValueGetterSubject<Output, Failure: Error>: Publisher {
    typealias Output = Output
    typealias Failure = Failure
    
    private let currentValueSubject: CurrentValueSubject<Output, Failure>
    
    var value: Output {
        currentValueSubject.value
    }
    
    func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        currentValueSubject.receive(subscriber: subscriber)
    }
    
    fileprivate init(_ currentValueSubject: CurrentValueSubject<Output, Failure>) {
        self.currentValueSubject = currentValueSubject
    }
}

extension CurrentValueSubject {
    func eraseToGetter() -> CurrentValueGetterSubject<Output, Failure> {
        .init(self)
    }
}
