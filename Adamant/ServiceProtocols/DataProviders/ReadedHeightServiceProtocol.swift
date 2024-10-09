//
//  ReadedHeightProvider.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol ReadedHeightServiceProtocol {
    func getLastReadedTimeStamp(adress: String) async -> Double?
    func setFirstReadedTimeStamp(adress: String, transactions: Set<ChatTransaction>) async
}
