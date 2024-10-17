//
//  APIResponseModel.swift
//  Adamant
//
//  Created by Andrew G on 17.11.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

public struct APIResponseModel: Sendable {
    public let result: ApiServiceResult<Data>
    public let data: Data?
    public let code: Int?
    
    public init(result: ApiServiceResult<Data>, data: Data?, code: Int?) {
        self.result = result
        self.data = data
        self.code = code
    }
}
