//
//  InfoServiceStatusDTO.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

struct InfoServiceStatusDTO: Codable, Sendable {
    let success: Bool
    let date: Int
    let ready: Bool
    let updating: Bool
    let next_update: Int
    let last_updated: Int?
    let version: String
}
