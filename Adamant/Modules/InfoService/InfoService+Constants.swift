//
//  InfoService+Constants.swift
//  Adamant
//
//  Created by Andrew G on 29.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit

extension InfoService {
    static let healthCheckParameters = CoinHealthCheckParameters(
        normalUpdateInterval: 210,
        crucialUpdateInterval: 30,
        onScreenUpdateInterval: 10,
        threshold: 1800,
        normalServiceUpdateInterval: .infinity,
        crucialServiceUpdateInterval: .infinity,
        onScreenServiceUpdateInterval: .infinity
    )
    
    static var symbol: String {
        .localized("InfoService.InfoService")
    }
    
    static var nodes: [Node] {
        [.makeDefaultNode(url: .init(string: "https://info2.adm.im")!)]
    }
}
