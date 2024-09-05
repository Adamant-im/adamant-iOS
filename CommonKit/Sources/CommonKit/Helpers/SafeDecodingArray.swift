//
//  SafeDecodingArray.swift
//
//
//  Created by Andrew G on 30.07.2024.
//

public struct SafeDecodingArray<T: Codable> {
    public let values: [T]
    
    init(_ values: [T]) {
        self.values = values
    }
}

extension SafeDecodingArray: Sequence {
    public typealias Element = T
    public typealias Iterator = IndexingIterator<[Element]>
    
    public func makeIterator() -> Iterator {
        values.makeIterator()
    }
}

extension SafeDecodingArray: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

extension SafeDecodingArray: Decodable {
    struct Item<Value: Decodable> {
        let value: Value?
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let items = try container.decode([Item<T>].self)
        values = items.compactMap { $0.value }
    }
}

extension SafeDecodingArray.Item: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try? container.decode(Value.self)
    }
}
