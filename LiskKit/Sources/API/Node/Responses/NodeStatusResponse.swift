//
//  NodeStatusResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 12/27/17.
//

import Foundation

extension Node {

    public struct NodeStatusResponse: APIResponse {

        public let data: NodeStatusModel
    }
}
