//
//  NetworkFileManagerProtocol.swift
//
//
//  Created by Stanislav Jelezoglo on 20.02.2024.
//

import Foundation

protocol NetworkFileManagerProtocol {
    func uploadFiles(_ data: Data, type: NetworkFileProtocolType) async throws -> String
    func downloadFile(_ id: String, type: String) async throws -> Data
}
