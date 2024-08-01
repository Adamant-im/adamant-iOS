//
//  HealthCheckWrapper+Extension.swift
//  Adamant
//
//  Created by Andrew G on 04.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

extension HealthCheckWrapper {
    var chosenFastestNodeId: UUID? {
        fastestNodeMode
            ? sortedAllowedNodes.first?.id
            : nil
    }
}
