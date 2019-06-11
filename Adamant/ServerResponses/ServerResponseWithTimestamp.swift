//
//  ServerResponseWithTimestamp.swift
//  Adamant
//
//  Created by Anokhov Pavel on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

protocol ServerResponseWithTimestamp {
    var nodeTimestamp: TimeInterval { get }
}

extension ServerResponse: ServerResponseWithTimestamp {
    
}
