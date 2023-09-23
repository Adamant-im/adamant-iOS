//
//  URL+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 17.07.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

extension URL: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        self.init(string: rawValue)
    }
    
    public var rawValue: String {
        absoluteString
    }
}
