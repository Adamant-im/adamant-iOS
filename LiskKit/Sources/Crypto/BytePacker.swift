/*
 This file is part of ByteBackpacker Project. It is subject to the license terms in the LICENSE file found in the top-level directory of this distribution and at https://github.com/michaeldorner/ByteBackpacker/blob/master/LICENSE. No part of ByteBackpacker Project, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the LICENSE file.
 */

import Foundation

internal struct BytePacker {

    /// ByteOrder
    ///
    /// Byte order can be either big or little endian.
    internal enum ByteOrder {
        case bigEndian
        case littleEndian
    }

    /// Pack method convinience method
    ///
    /// - Parameters:
    ///   - value: value to pack of type `T`
    ///   - byteOrder: Byte order (wither little or big endian)
    /// - Returns: Byte array
    static func pack<T: Any>( _ value: T, byteOrder: ByteOrder) -> [UInt8] {
        var value = value // inout works only for var not let types
        let valueByteArray = withUnsafePointer(to: &value) {
            Array(UnsafeBufferPointer(start: $0.withMemoryRebound(to: UInt8.self, capacity: 1){$0}, count: MemoryLayout<T>.size))
        }
        return (byteOrder == .littleEndian) ? valueByteArray : valueByteArray.reversed()
    }
}
