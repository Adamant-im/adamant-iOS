//
//  AddressFactory.swift
//
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

public struct AddressFactory {
    public static func create(_ plainAddress: String) throws -> Address {
        do {
            return try Cashaddr(plainAddress)
        } catch AddressError.invalidVersionByte {
            throw AddressError.invalidVersionByte
        } catch AddressError.invalidScheme {
            throw AddressError.invalidScheme
        } catch AddressError.invalid {
            return try LegacyAddress(plainAddress)
        }
    }
    
    private static func getBase58DecodeAsBytes(address: String, length: Int) -> [UTF8.CodeUnit]? {
        let b58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        
        var output: [UTF8.CodeUnit] = Array(repeating: 0, count: length)
        
        for i in 0..<address.count {
            let index = address.index(address.startIndex, offsetBy: i)
            let charAtIndex = address[index]
            
            guard let charLoc = b58Chars.firstIndex(of: charAtIndex) else { continue }
            
            var p = b58Chars.distance(from: b58Chars.startIndex, to: charLoc)
            for j in stride(from: length - 1, through: 0, by: -1) {
                p += 58 * Int(output[j] & 0xFF)
                output[j] = UTF8.CodeUnit(p % 256)
                
                p /= 256
            }
            
            guard p == 0 else { return nil }
        }
        
        return output
    }
    
    public static func isValid(bitcoinAddress address: String) -> Bool {
        guard address.count >= 26 && address.count <= 35,
            address.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil,
            let decodedAddress = getBase58DecodeAsBytes(address: address, length: 25),
            decodedAddress.count >= 4
            else { return false }
        
        let decodedAddressNoCheckSum = Array(decodedAddress.prefix(decodedAddress.count - 4))
        
        let hashedSum = Crypto.sha256sha256(Data(decodedAddressNoCheckSum))
        
        let checkSum = Array(decodedAddress.suffix(from: decodedAddress.count - 4))
        let hashedSumHeader = Array(hashedSum.prefix(4))
        
        return hashedSumHeader == checkSum
    }
}
