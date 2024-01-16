//
//  ExistModel.swift
//
//
//  Created by Stanislav Jelezoglo on 19.12.2023.
//

import Foundation

public struct ExistModel: APIResponse {
    public struct ExistData: Decodable {
        public let isExists: Bool
    }

    public let data: ExistData
}
