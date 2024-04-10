//
//  IPFSDTO.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 10.04.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

struct IpfsDTO: Decodable {
    let cids: [String]
}
