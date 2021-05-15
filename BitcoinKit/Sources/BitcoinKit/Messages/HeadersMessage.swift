//
//  HeadersMessage.swift
//
//  Copyright © 2018 Kishikawa Katsumi
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public struct HeadersMessage {
    // The main client will never send us more than this number of headers.
    public static let MAX_HEADERS: Int = 2000

    /// Number of block headers
    public var count: VarInt {
        return VarInt(headers.count)
    }
    /// Block headers
    public let headers: [BlockHeader]

    public func serialized() -> Data {
        var data = Data()
        data += count.serialized()
        for header in headers {
            data += header.serialized()
        }
        return data
    }

    public static func deserialize(_ data: Data) throws -> HeadersMessage {
        let byteStream = ByteStream(data)
        let count = byteStream.read(VarInt.self)
        let countValue = count.underlyingValue
        guard countValue <= MAX_HEADERS else {
            throw ProtocolError.error("Too many headers: got \(countValue) which is larger than \(MAX_HEADERS)")
        }
        var blockHeaders = [BlockHeader]()
        for _ in 0..<countValue {
            let blockHeader: BlockHeader = BlockHeader.deserialize(byteStream)
            blockHeaders.append(blockHeader)
        }
        return HeadersMessage(headers: blockHeaders)
    }
}

public struct BlockHeader {
    /// Block version information (note, this is signed)
    public let version: Int32
    /// The hash value of the previous block this particular block references
    public let prevBlock: Data
    /// The reference to a Merkle tree collection which is a hash of all transactions related to this block
    public let merkleRoot: Data
    /// A Unix timestamp recording when this block was created (Currently limited to dates before the year 2106!)
    public let timestamp: UInt32
    /// The calculated difficulty target being used for this block
    public let bits: UInt32
    /// The nonce used to generate this block… to allow variations of the header and compute different hashes
    public let nonce: UInt32
    /// Number of transaction entries
    public let transactionCount: VarInt
    
    public func serialized() -> Data {
        var data = Data()
        data += version
        data += prevBlock
        data += merkleRoot
        data += timestamp
        data += bits
        data += nonce
        data += transactionCount.serialized()
        return data
    }
    
    public static func deserialize(_ data: Data) -> BlockHeader {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }
    
    static func deserialize(_ byteStream: ByteStream) -> BlockHeader {
        let version = byteStream.read(Int32.self)
        let prevBlock = byteStream.read(Data.self, count: 32)
        let merkleRoot = byteStream.read(Data.self, count: 32)
        let timestamp = byteStream.read(UInt32.self)
        let bits = byteStream.read(UInt32.self)
        let nonce = byteStream.read(UInt32.self)
        let transactionCount = byteStream.read(VarInt.self)
        return BlockHeader(version: version, prevBlock: prevBlock, merkleRoot: merkleRoot, timestamp: timestamp, bits: bits, nonce: nonce, transactionCount: transactionCount)
    }
}
