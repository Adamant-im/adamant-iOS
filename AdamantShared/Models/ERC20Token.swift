//
//  ERC20Token.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/06/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit

struct ERC20Token {
    let symbol: String
    let name: String
    let contractAddress: String
    let decimals: Int
    let naturalUnits: Int
    var logo: UIImage {
        UIImage(named: "\(symbol.lowercased())_wallet") ?? UIImage()
    }
}
