//
//  APIService.swift
//  Lisk
//
//  Created by Andrew Barba on 1/8/18.
//

import Foundation

/// API Service
public protocol APIService {

    var client: APIClient { get }

    init(client: APIClient)
}
