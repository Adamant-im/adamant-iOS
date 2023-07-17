//
//  IdentifiableContainer.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct IdentifiableContainer<T: RawRepresentable<String>>: Identifiable {
    let value: T
    
    var id: String {
        value.rawValue
    }
}
