//
//  Status.swift
//  Adamant
//
//  Created by Anton Boyarkin on 29/05/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

struct Status: Codable {
    var loaded: Bool
    var now: Int
    let blocksCount: Int
}

extension Status: WrappableModel {
    static let ModelKey = "staus"
}

// JSON : {"success":true,"loaded":true,"now":3110042,"blocksCount":0}
