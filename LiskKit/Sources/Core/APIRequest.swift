//
//  APIRequest.swift
//  LiskPackageDescription
//
//  Created by Andrew Barba on 4/11/18.
//

import Foundation

public struct APIRequest {

    /// Combination of column and sort direction
    public struct Sort {

        public enum Direction: String {
            case ascending = "asc"
            case descending = "desc"
        }

        public let column: String

        public let direction: Direction

        public var value: String {
            return "\(column):\(direction.rawValue)"
        }
        
        public init(_ column: String, direction: Direction = .ascending) {
            self.column = column
            self.direction = direction
        }
    }

    /// Property join type
    public enum Join: String {
        case or = ""
        case and = "AND:"
    }
}
