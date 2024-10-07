//
//  ReadedHeightProvider.swift
//  Adamant
//
//  Created by Аркадий Торвальдс on 30.09.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

protocol ReadedHeightServiceProtocol {
    func getLastReadedHeight(adress: String) async -> Int
    func setLastReadedHeight(address: String?, height: Int64?) async
}
