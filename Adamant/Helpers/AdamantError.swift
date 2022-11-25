//
//  AdamantError.swift
//  Adamant
//
//  Created by Anokhov Pavel on 06.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

struct AdamantError: LocalizedError {
    public let errorDescription: String?
    
    init(message: String) {
        self.errorDescription = message
    }
}
