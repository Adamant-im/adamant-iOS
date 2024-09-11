//
//  SafeDecodingDictionary.swift
//
//
//  Created by Andrew G on 02.08.2024.
//

public struct SafeDecodingDictionary<Key: Codable & Hashable, Value: Codable> {
    public let values: [Key: Value]
    
    init(_ values: [Key: Value]) {
        self.values = values
    }
}

extension SafeDecodingDictionary: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

extension SafeDecodingDictionary: Decodable {
    struct KeyItem<T: Decodable & Hashable>: Hashable {
        let value: T?
    }
    
    struct ValueItem<T: Decodable> {
        let value: T?
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let items = try container.decode([KeyItem<Key>: ValueItem<Value>].self)
        
        let keysAndValues: [(Key, Value)] = items.compactMap { keyItem, valueItem in
            guard
                let key = keyItem.value,
                let value = valueItem.value
            else { return nil }
            
            return (key, value)
        }
        
        values = .init(uniqueKeysWithValues: keysAndValues)
    }
}

extension SafeDecodingDictionary.KeyItem: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(T.self)
    }
}

extension SafeDecodingDictionary.ValueItem: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(T.self)
    }
}
