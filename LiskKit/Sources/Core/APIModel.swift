//
//  APIModel.swift
//  Lisk
//
//  Created by Andrew Barba on 1/9/18.
//

import Foundation

/// API model
public protocol APIModel: Decodable, Hashable {
    
}

/// Common model for single message response
public struct APIMessageModel: APIModel {

    public let message: String
}
