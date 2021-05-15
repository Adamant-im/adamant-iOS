//
//  DappsResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

extension Dapps {

    public struct DappsResponse: APIResponse {

        public let data: [DappModel]
    }
}
