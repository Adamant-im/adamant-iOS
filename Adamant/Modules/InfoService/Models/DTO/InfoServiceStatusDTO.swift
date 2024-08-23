//
//  InfoServiceStatusDTO.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

struct InfoServiceStatusDTO: Codable {
    let success: Bool
    let date: Int
    let ready: Bool
    let updating: Bool
    let next_update: Int
    let last_updated: Int?
    let version: String
}

//{
//  success: boolean,
//  // Unix timestamp of the server time in ms
//  date: number,
//  // Whether Currencyinfo has fetched its first rates
//  ready: boolean,
//  // Whether Currencyinfo is updating the rates right now
//  updating: boolean,
//  // Unix timestamp in ms of the next update or the current one when updating
//  next_update: number,
//  // Unix timestamp of the last update in ms or `null` before the first rates have been fetched
//  last_updated: number | null,
//  // Currencyinfo version in `x.y.z` format
//  version: string
//}
