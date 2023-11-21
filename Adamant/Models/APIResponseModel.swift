//
//  APIResponseModel.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

struct APIResponseModel {
    let result: ApiServiceResult<Data>
    let data: Data?
    let code: Int?
}
