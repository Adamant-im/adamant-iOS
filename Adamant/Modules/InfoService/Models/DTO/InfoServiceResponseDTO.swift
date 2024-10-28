//
//  InfoServiceResponseDTO.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

struct InfoServiceResponseDTO<Body: Codable & Sendable>: Codable, Sendable {
    let success: Bool
    let date: Int
    let result: Body?
}
