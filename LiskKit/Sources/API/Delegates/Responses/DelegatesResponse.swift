//
//  DelegateResponse.swift
//  Lisk
//
//  Created by Andrew Barba on 1/8/18.
//

import Foundation

extension Delegates {

    public struct DelegatesResponse: APIResponse {

        public let data: [DelegateModel]
    }
}
