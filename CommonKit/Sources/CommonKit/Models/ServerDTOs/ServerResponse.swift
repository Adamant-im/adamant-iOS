//
//  ServerResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

public protocol WrappableModel: Decodable {
    static var ModelKey: String { get }
}

public protocol WrappableCollection: Decodable {
    static var CollectionKey: String { get }
}

open class ServerResponse: Decodable, @unchecked Sendable {
    public struct CodingKeys: CodingKey {
        public var intValue: Int?
        public var stringValue: String
        
        public init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = "\(intValue)"
        }
        
        public init?(stringValue: String) {
            self.stringValue = stringValue
        }
        
        public static let success = CodingKeys(stringValue: "success")!
        public static let error = CodingKeys(stringValue: "error")!
        public static let nodeTimestamp = CodingKeys(stringValue: "nodeTimestamp")!
    }
    
    public let success: Bool
    public let error: String?
    public let nodeTimestamp: TimeInterval
    
    public init(success: Bool, error: String?, nodeTimestamp: TimeInterval) {
        self.success = success
        self.error = error
        self.nodeTimestamp = nodeTimestamp
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.success = try container.decode(Bool.self, forKey: CodingKeys.success)
        self.error = try? container.decode(String.self, forKey: CodingKeys.error)
        self.nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
    }
}

public final class ServerModelResponse<T: WrappableModel>: ServerResponse, @unchecked Sendable {
    public let model: T?
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: CodingKeys.success)
        let nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
        let error = try? container.decode(String.self, forKey: CodingKeys.error)
        self.model = try? container.decode(T.self, forKey: CodingKeys(stringValue: T.ModelKey)!)
        
        super.init(success: success, error: error, nodeTimestamp: nodeTimestamp)
    }
}

public final class ServerCollectionResponse<T: WrappableCollection>: ServerResponse, @unchecked Sendable {
    public let collection: [T]?
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: CodingKeys.success)
        let error = try? container.decode(String.self, forKey: CodingKeys.error)
        let nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
        self.collection = try? container.decode([T].self, forKey: CodingKeys(stringValue: T.CollectionKey)!)
        
        super.init(success: success, error: error, nodeTimestamp: nodeTimestamp)
    }
}

// MARK: - JSON
/*
{
    "success": true,
    "error": "optional error description, if success = false",
    "model": { },
    "collection": [ ]
}
*/
