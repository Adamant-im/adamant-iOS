//
//  BTCRPCServerResponce.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class BTCRPCServerResponce<T:Decodable>: Decodable {
    let result: T?
    let error: String?
    let id: String?
}
