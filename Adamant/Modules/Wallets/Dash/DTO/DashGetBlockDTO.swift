//
//  DashGetBlockDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashGetBlockDTO: Codable {
    let method: String
    let params: [String]
    
    init(hash: String) {
        self.method = "getblock"
        self.params = [hash]
    }
}
