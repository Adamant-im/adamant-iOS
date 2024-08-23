//
//  InfoServiceHistoryItemDTO.swift
//  Adamant
//
//  Created by Andrew G on 23.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

struct InfoServiceHistoryItemDTO: Codable {
    let _id: String
    let date: Int
    let tickers: [String: Double]?
}
