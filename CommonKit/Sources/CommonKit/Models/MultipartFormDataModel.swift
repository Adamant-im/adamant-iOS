//
//  MultipartFormDataModel.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 16.05.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Foundation

public struct MultipartFormDataModel: Sendable {
    public let keyName: String
    public let fileName: String
    public let data: Data
    
    public init(keyName: String, fileName: String, data: Data) {
        self.keyName = keyName
        self.fileName = fileName
        self.data = data
    }
}
