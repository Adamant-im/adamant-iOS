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
public struct APIError: LocalizedError, Equatable {
    public let message: String
    public var code: Int?
    
    public var errorDescription: String? { message }

    public init(message: String, code: Int?) {
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

public extension APIError {
    public static let noNetwork = Self.unexpected(code: nil)
    
    /// Describes an unexpected error
    public static func unexpected(code: Int?) -> Self {
        .init(message: "Unexpected Error", code: code)
    }

    /// Describes an unknown error response
    public static func unknown(code: Int?) -> Self {
        .init(message: "Unknown Error", code: code)
    }
}
