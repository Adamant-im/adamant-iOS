//
//  NetworkFileManagerProtocol.swift
//
//
//  Created by Stanislav Jelezoglo on 20.02.2024.
//

import Foundation

public enum NetworkFileProtocolType: String {
    case base
}

protocol NetworkFileManagerProtocol {
    func uploadFiles(_ data: Data, type: NetworkFileProtocolType) async throws -> String
    func downloadFile(_ id: String, type: String) async throws -> Data
}
