//
//  PeerResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 1/8/18.
//

import Foundation

extension Peers {

    public struct PeersResponse: APIResponse {

        public let data: [PeerModel]
    }
}
