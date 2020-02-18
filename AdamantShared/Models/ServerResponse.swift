//
//  ServerResponse.swift
//  Adamant
//
//  Created by Anokhov Pavel on 11.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol WrappableModel: Decodable {
    static var ModelKey: String { get }
}

protocol WrappableCollection: Decodable {
    static var CollectionKey: String { get }
}

class ServerResponse: Decodable {
    struct CodingKeys: CodingKey {
        var intValue: Int?
        var stringValue: String
        
        init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
        init?(stringValue: String) { self.stringValue = stringValue }
        
        static let success = CodingKeys(stringValue: "success")!
        static let error = CodingKeys(stringValue: "error")!
        static let nodeTimestamp = CodingKeys(stringValue: "nodeTimestamp")!
    }
    
    let success: Bool
    let error: String?
    let nodeTimestamp: TimeInterval
    
    init(success: Bool, error: String?, nodeTimestamp: TimeInterval) {
        self.success = success
        self.error = error
        self.nodeTimestamp = nodeTimestamp
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.success = try container.decode(Bool.self, forKey: CodingKeys.success)
        self.error = try? container.decode(String.self, forKey: CodingKeys.error)
        self.nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
    }
}

class ServerModelResponse<T: WrappableModel>: ServerResponse  {
    let model: T?
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let success = try container.decode(Bool.self, forKey: CodingKeys.success)
        let nodeTimestamp = try container.decode(TimeInterval.self, forKey: CodingKeys.nodeTimestamp)
        let error = try? container.decode(String.self, forKey: CodingKeys.error)
        self.model = try? container.decode(T.self, forKey: CodingKeys(stringValue: T.ModelKey)!)
        
        super.init(success: success, error: error, nodeTimestamp: nodeTimestamp)
    }
}

class ServerCollectionResponse<T: WrappableCollection>: ServerResponse  {
    let collection: [T]?
    
    required init(from decoder: Decoder) throws {
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
