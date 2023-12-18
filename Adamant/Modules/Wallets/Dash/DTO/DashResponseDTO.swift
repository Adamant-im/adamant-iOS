//
//  DashResponseDTO.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct DashResponseDTO<T: Codable>: Codable {
    let result: T?
    let error: DashErrorDTO?
}
