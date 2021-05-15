//
//  APIResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 12/27/17.
//

import Foundation

/// Protocol describing an response
public protocol APIResponse: Decodable {

    associatedtype APIData: Any

    /// All successful responses have a data key
    var data: APIData { get }
}
