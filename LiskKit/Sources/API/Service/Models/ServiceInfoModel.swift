//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 26.12.2023.
//

import Foundation

public struct ServiceInfoModel: APIModel {
    public let version: String
    public let networkNodeVersion: String
}

/*
 {
     "build":"2023-12-22T04:55:07.960Z",
     "description":"Lisk Service Gateway",
     "name":"lisk-service-gateway",
     "version":"0.7.3",
     "networkNodeVersion":"5.0",
     "chainID":"00000000"
 }
 */
