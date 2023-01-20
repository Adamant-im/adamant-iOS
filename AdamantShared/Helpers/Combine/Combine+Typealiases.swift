//
//  Combine+Typealiases.swift
//  Adamant
//
//  Created by Andrey Golubenko on 28.12.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Combine

typealias ObservableProperty<T> = CurrentValueSubject<T, Never>
typealias ObservableVariable<T> = CurrentValueGetterSubject<T, Never>
typealias ObservableSender<T> = PassthroughSubject<T, Never>
typealias Observable<T> = AnyPublisher<T, Never>
