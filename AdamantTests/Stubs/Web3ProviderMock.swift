//
//  Web3ProviderMock.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import Web3Core

final class Web3ProviderMock: Web3Provider {
    var network: Networks?
    var attachedKeystoreManager: KeystoreManager?
    var policies: Policies
    var url: URL
    var session: URLSession
    
    init(
        network: Networks? = nil,
        attachedKeystoreManager: KeystoreManager? = nil,
        policies: Policies = .auto,
        url: URL = Web3ProviderMock.defaultURL,
        session: URLSession = .shared
    ) {
        self.network = network
        self.attachedKeystoreManager = attachedKeystoreManager
        self.policies = policies
        self.url = url
        self.session = session
    }
}

extension Web3ProviderMock {
    private static let defaultURL = URL(string: "http://google.com")!
}
