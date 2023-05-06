//
//  Combine+Typealiases.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine

typealias ObservableSender<Output> = PassthroughSubject<Output, Never>
typealias AnyObservable<Output> = AnyPublisher<Output, Never>
typealias Observable<Output> = Publisher<Output, Never>
