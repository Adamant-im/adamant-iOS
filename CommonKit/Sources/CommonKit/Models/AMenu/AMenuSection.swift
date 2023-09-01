//
//  AMenuSection.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.07.2023.
//

import Foundation

public struct AMenuSection {

    public let menuItems: [AMenuItem]
    
    public init(_ menuItems: [AMenuItem]) {
        self.menuItems = menuItems
    }
}
