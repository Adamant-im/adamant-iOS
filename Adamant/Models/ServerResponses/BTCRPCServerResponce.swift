//
//  BTCRPCServerResponce.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

struct BTCRPCServerResponce<T: Decodable & Sendable>: Decodable, Sendable {
    let result: T?
    let error: BTCRPCError?
    let id: String?
}

struct BTCRPCError: Decodable, Sendable {
    let code: Int
    let message: String
}
