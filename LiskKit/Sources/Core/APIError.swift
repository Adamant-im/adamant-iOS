//
//  APIError.swift
//  Lisk
//
//  Created by Andrew Barba on 12/27/17.
//

import Foundation

/// Protocol describing an error
public struct APIErrors: Decodable {

    public let errors: [APIError]

    private enum Keys: String, CodingKey {
        case errors
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
            self.errors = try container.decode([APIError].self, forKey: .errors)
    }
    
    public init(errors: [APIError]) {
        self.errors = errors
    }
}

/// Protocol describing an error
public struct APIError: LocalizedError {
    public let message: String
    
    public var errorDescription: String? { message }

    public init(message: String) {
        self.message = message
    }
}

extension APIError: Decodable {

    private enum Keys: String, CodingKey {
        case message
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        if let message = try? container.decode(String.self, forKey: .message) {
            self.message = message
        } else {
            self.message = try container.decode(String.self, forKey: .error)
        }
    }
}

extension APIError {

    /// Describes an unexpected error
    public static let unexpected = APIError(message: "Unexpected Error")

    /// Describes an unknown error response
    public static let unknown = APIError(message: "Unknown Error")
}
