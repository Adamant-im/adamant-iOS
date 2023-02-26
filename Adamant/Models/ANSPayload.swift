//
//  ANSPayload.swift
//  Adamant
//
//  Created by Andrey Golubenko on 23.11.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

struct ANSPayload: Codable {
    let token: String
    let provider: Provider
    let action: Action
}

extension ANSPayload {
    enum Provider: String, Codable {
        case apns
        case apnsSandbox = "apns-sandbox"
    }
    
    enum Action: String, Codable {
        case add
        case remove
    }
}
