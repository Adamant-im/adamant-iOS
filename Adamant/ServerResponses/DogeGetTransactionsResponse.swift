//
//  DogeGetTransactionsResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 03/04/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

class DogeGetTransactionsResponse: Decodable {
    let totalItems: Int
    let from: Int
    let to: Int
    
    let items: [BTCRawTransaction]
}

/* Json

{
    "totalItems": 1,
    "from": 0,
    "to": 1,
    "items": []
}
 
*/
