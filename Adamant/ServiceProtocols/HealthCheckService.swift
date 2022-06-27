//
//  HealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

protocol HealthCheckDelegate: AnyObject {
    func healthCheckFinished()
}

protocol HealthCheckService: AnyObject {
    var nodes: [Node] { get set }
    var delegate: HealthCheckDelegate? { get set }
    
    func healthCheck()
    func getPreferredNode(fastest: Bool, needWS: Bool) -> Node?
}
