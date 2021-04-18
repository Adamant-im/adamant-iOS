//
//  BlocksResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 1/9/18.
//

import Foundation

extension Blocks {

    public struct BlocksResponse: APIResponse {

        public let data: [BlockModel]
    }
}
