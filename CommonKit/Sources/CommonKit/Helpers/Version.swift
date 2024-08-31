//
//  Version.swift
//
//
//  Created by Andrew G on 22.08.2024.
//

public struct Version {
    public let versions: [Int]
    
    public init(_ versions: [Int]) {
        self.versions = versions
    }
}

public extension Version {
    var string: String {
        versions.map { String($0) }.joined(separator: ".")
    }
    
    init?(_ string: String) {
        let versions = string
            .filter { $0.isNumber || $0 == "." }
            .split(separator: ".")
            .compactMap { Int($0) }
        
        guard !versions.isEmpty else { return nil }
        self.versions = versions
    }
}

extension Version: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        for i in .zero ..< max(lhs.versions.endIndex, rhs.versions.endIndex) {
            let left = lhs.versions[safe: i] ?? .zero
            let right = rhs.versions[safe: i] ?? .zero
            
            if left < right {
                return true
            } else if left > right {
                return false
            }
        }
        
        return false
    }
}

extension Version: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for i in .zero ..< max(lhs.versions.endIndex, rhs.versions.endIndex) {
            guard lhs.versions[safe: i] ?? .zero == rhs.versions[safe: i] ?? .zero
            else { return false }
        }
        
        return true
    }
}
