//
//  HealthCheckService.swift
//  Adamant
//
//  Created by Андрей on 06.06.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation
import CommonKit

protocol HealthCheckDelegate: AnyObject {
    func healthCheckUpdate()
}

protocol HealthCheckService: AnyObject {
    var nodes: [Node] { get set }
    var delegate: HealthCheckDelegate? { get set }
    
    func healthCheck()
}
