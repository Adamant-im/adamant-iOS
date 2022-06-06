//
//  HealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

protocol HealthCheckService: AnyObject {
    /// - Parameters:
    ///     - nodes: array of nodes for health check
    ///     - firstWorkingNodeHandler: will be called when the first working node is found
    ///     - allowedNodesHandler: will send array of allowed nodes sorted by ping ascending after health check finish
    func healthCheck(
        nodes: [Node],
        firstWorkingNodeHandler: @escaping (Node) -> Void,
        allowedNodesHandler: @escaping ([Node]) -> Void
    )
}
