//
//  NodeStatusInfo.swift
//  Adamant
//
//  Created by Andrew G on 01.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct NodeStatusInfo: Equatable {
    let ping: TimeInterval
    let height: Int
    let wsEnabled: Bool
    let wsPort: Int?
    let version: String?
}
