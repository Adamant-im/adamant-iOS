//
//  ValueSubject.swift
//  CommonKit
//
//  Created by Andrew G on 16.10.2024.
//

import Combine

public protocol ValueSubject: Subject {
    var value: Output { get set }
}

extension CurrentValueSubject: ValueSubject {}
