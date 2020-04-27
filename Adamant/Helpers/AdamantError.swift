//
//  AdamantError.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantError: Error, CustomStringConvertible {
    public let message: String
    public let internalError: Error?
    
    init(message: String, error: Error? = nil) {
        self.message = message
        self.internalError = error
    }
    
    // MARK: CustomStringConvertible
    public var description: String {
        return message
    }
}
