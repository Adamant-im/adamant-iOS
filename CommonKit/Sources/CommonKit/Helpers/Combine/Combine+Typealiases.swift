//
//  Combine+Typealiases.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine

public typealias ObservableSender<Output> = PassthroughSubject<Output, Never>
public typealias AnyObservable<Output> = AnyPublisher<Output, Never>
public typealias Observable<Output> = Publisher<Output, Never>
