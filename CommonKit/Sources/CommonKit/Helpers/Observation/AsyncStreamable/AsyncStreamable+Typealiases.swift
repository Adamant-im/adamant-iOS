//
//  AsyncStreamable+Typealiases.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

public typealias SendableObservableValue<Element: Sendable> = SendablePublisher<ObservableValue<Element>>
public typealias SendableObservableSender<Element: Sendable> = SendablePublisher<ObservableSender<Element>>
