//
//  DashErrorDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashErrorDTO: Codable, LocalizedError {
    let code: Int
    let message: String
    
    var errorDescription: String? {
        message
    }
}
