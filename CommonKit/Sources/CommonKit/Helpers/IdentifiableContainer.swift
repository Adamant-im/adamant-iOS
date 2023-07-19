//
//  IdentifiableContainer.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public struct IdentifiableContainer<T: RawRepresentable<String>>: Identifiable {
    public let value: T
    
    public var id: String {
        value.rawValue
    }
    
    public init(value: T) {
        self.value = value
    }
}
