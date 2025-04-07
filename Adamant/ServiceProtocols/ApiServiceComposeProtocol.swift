//
//  ApiServiceComposeProtocol.swift
//  Adamant
//
//  Created by Andrew G on 21.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol ApiServiceComposeProtocol {
    func get(_ group: NodeGroup) -> ApiServiceProtocol?
}
