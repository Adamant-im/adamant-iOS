//
//  ApiManagerProtocol.swift
//
//
//  Created by Stanislav Jelezoglo on 26.02.2024.
//

import Foundation

protocol ApiManagerProtocol {
    func uploadFile(data: Data) async throws -> String
    func downloadFile(id: String) async throws -> Data
}
