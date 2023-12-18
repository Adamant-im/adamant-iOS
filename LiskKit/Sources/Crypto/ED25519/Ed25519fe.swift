import Foundation
//
//  ed25519_fe.swift
//
//  Copyright 2017 pebble8888. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//    arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//    including commercial applications, and to alter it and redistribute it
//    freely, subject to the following restrictions:
//
//    1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would be
//    appreciated but is not required.
//
//    2. Altered source versions must be plainly marked as such, and must not be
//    misrepresented as being the original software.
//
//    3. This notice may not be removed or altered from any source distribution.
//
struct shortsc {
    var v: [UInt32] // 16
    init() {
        v = [UInt32](repeating: 0, count: 16)
    }
}

struct sc {
    var v: [UInt32] // 32
    init() {
        v = [UInt32](repeating: 0, count: 32)
    }

    private static let k = 32

    /* Arithmetic modulo the group order
     order
     = 2^252 + 27742317777372353535851937790883648493
     = 7237005577332262213973186563042994240857116359379907606001950938285454250989
     = 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed

     p  = 2^255 - 19
     = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed
     */

    // little endian group order m
    private static let m: [UInt32] =
        [0xED, 0xD3, 0xF5, 0x5C, 0x1A, 0x63, 0x12, 0x58, 0xD6, 0x9C, 0xF7, 0xA2, 0xDE, 0xF9, 0xDE, 0x14,
         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10]

    /*
     for barrett_reduce algorithm
     b = 256 = 2^8
     k = 32 = 2^5
     b^(2k) = (2^8)^64 = 2^512
     mu = 2^512 // m
     = 1852673427797059126777135760139006525645217721299241702126143248052143860224795
     = 0x0fffffffffffffffffffffffffffffffeb2106215d086329a7ed9ce5a30a2c131b
     */
    private static let mu: [UInt32] =
        [0x1B, 0x13, 0x2C, 0x0A, 0xA3, 0xE5, 0x9C, 0xED, 0xA7, 0x29, 0x63, 0x08, 0x5D, 0x21, 0x06, 0x21,
         0xEB, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0F]

    private static func lt(_ a: UInt32, _ b: UInt32) -> UInt32 /* 16-bit inputs */ {
        if a < b {
            return 1
        } else {
            return 0
        }
    }

    /// if r > m: r = r - m
    /// else    : r = r
    private static func reduce_add_sub(_ r: inout sc) {
        var val: UInt32 = 0
        var borrow: UInt32 = 0
        // r - m
        var t = [UInt8](repeating: 0, count: 32)

        for i in 0..<k {
            val += m[i]
            borrow = lt(r.v[i], val)
            let vv = Int64(r.v[i]) - Int64(val) + Int64(borrow << 8)
            assert(vv >= 0 && vv <= 0xff)
            t[i] = UInt8(vv)
            val = borrow
        }
        // no borrow: mask = 0xffffffff -> r = r - m
        // borrow   : mask = 0x0        -> r = r
        let mask = UInt32(bitPattern: Int32(borrow)-1)
        for i in 0..<k {
            r.v[i] ^= mask & (r.v[i] ^ UInt32(t[i]))
        }
    }

    /// Reduce coefficients of x before calling barrett_reduce
    /// r = x mod m
    ///
    /// b = 256 = 2^8
    /// k = 32 = 2^5
    /// x < b^(2k)
    /// x: LSB
    private static func barrett_reduce(_ r: inout sc, _ x: [UInt32] /* 64 */) {
        assert(x.count == 64)
        /* See HAC(HANDBOOK OF APPLIED CRYPTOGRAPHY), Alg. 14.42 */
        // STEP1
        // q1 = floor(x / b^(k-1))
        // q2 <- q1 * mu
        var q2 = [UInt32](repeating: 0, count: 2*k+2) // LSB
        for i in 0...k {
            for j in 0...k {
                if i+j >= k-1 {
                    q2[i+j] += x[j+k-1] * mu[i]
                }
            }
        }

        // q3 = floor(q2 / b^(k+1))
        // q3 = (... + b^(k+1) * q2[k+1] + b^(k+2) * q2[k+2] + ... + b^(2k) * q2[2k] + b^(2k+1) * q2[2k+1])
        //    = q2[k+1] + b^1 * q2[k+1] + ... + b^(k-1) * q2[2k] + b^k * q2[2k+1]
        // Since q2[2k] has carry q2[2k+1] is zero.
        let carry1 = q2[k-1] >> 8
        q2[k] += carry1
        let carry2 = q2[k] >> 8
        q2[k+1] += carry2

        // STEP2,3
        // r1 = x (mod b^(k+1))
        var r1 = [UInt32](repeating: 0, count: k+1)
        for i in 0...k {
            r1[i] = x[i]
        }

        // r2 = q3 * m (mod b^(k+1))
        var r2 = [UInt32](repeating: 0, count: k+1)
        for i in 0...k-1 {
            for j in 0...k {
                if i+j < k+1 {
                    r2[i+j] += q2[j+k+1] * m[i]
                }
            }
        }
        for i in 0...k-1 {
            let carry = r2[i] >> 8
            r2[i+1] += carry
            r2[i] &= 0xff
        }
        r2[k] &= 0xff

        // r = r1 - r2 (or + b^(k+1))
        // last borrow means STEP3 for r < 0
        // r = (Q-q3) * m + R <= 2m
        // 2m = 2 * (0x10 * b^(k-1) + ...) = 0x20 * b^(k-1) + ... < b^k
        // so r can represented for b^0 y\_0 + b^1 y\_1 + ... + b^(k-1) y\_(k-1)
        // it means r[v] is zero
        var val: UInt32 = 0
        for i in 0...k-1 {
            val += r2[i]
            let borrow = lt(r1[i], val)
            let vv = Int64(r1[i]) - Int64(val) + Int64(borrow << 8)
            assert(vv >= 0 && vv <= 0xff)
            r.v[i] = UInt32(vv)
            val = borrow
        }

        // STEP4: twice or once or none
        reduce_add_sub(&r)
        reduce_add_sub(&r)
    }

    // check x is [0, m)
    static func sc25519_less_order(_ x: [UInt8] /* 32 */) -> Bool {
        if x.count != k {
            return false
        }
        for i in (0..<k).reversed() {
            if x[i] < m[i] {
                // less
                return true
            } else if x[i] > m[i] {
                // large
                return false
            }
        }
        // equal to m
        return false
    }

    static func sc25519_from32bytes(_ r: inout sc, _ x: [UInt8] /* 32 */) {
        assert(x.count >= k)
        var t = [UInt32](repeating: 0, count: k*2)
        for i in 0..<k {
            t[i] = UInt32(x[i])
        }
        for i in k..<k*2 {
            t[i] = 0
        }
        // r = t mod m
        sc.barrett_reduce(&r, t)
    }

    static func sc25519_from16bytes(_ r: inout shortsc, _ x: [UInt8] /* 16 */) throws {
        assert(x.count >= 16)
        for i in 0..<16 {
            r.v[i] = UInt32(x[i])
        }
    }

    static func sc25519_from64bytes(_ r: inout sc, _ x: [UInt8] /* 64 */) {
        assert(x.count == k*2)
        var t = [UInt32](repeating: 0, count: k*2)
        for i in 0..<k*2 {
            t[i] = UInt32(x[i])
        }
        // r = t mod b
        sc.barrett_reduce(&r, t)
    }

    static func sc25519_from_shortsc(_ r: inout sc, _ x: shortsc) {
        for i in 0..<16 {
            r.v[i] = x.v[i]
        }
        for i in 0..<16 {
            r.v[16+i] = 0
        }
    }

    static func sc25519_to32bytes(_ r: inout [UInt8] /* 32 */, _ x: sc) {
        assert(r.count == k)
        for i in 0..<k {
            r[i] = UInt8(x.v[i])
        }
    }

    static func sc25519_iszero_vartime(_ x: sc) -> Int {
        for i in 0..<k {
            if x.v[i] != 0 {
                return 0
            }
        }
        return 1
    }

    static func sc25519_isshort_vartime(_ x: sc) -> Int {
        for i in stride(from: 31, to: 15, by: -1) {
            if x.v[i] != 0 {
                return 0
            }
        }
        return 1
    }

    static func sc25519_lt_vartime(_ x: sc, _ y: sc) -> UInt {
        for i in stride(from: 31, through: 0, by: -1) {
            if x.v[i] < y.v[i] {
                return 1
            }
            if x.v[i] > y.v[i] {
                return 0
            }
        }
        return 0
    }

    static func sc25519_add(_ r: inout sc, _ x: sc, _ y: sc) {
        var carry: UInt32
        for i in 0..<k {
            r.v[i] = x.v[i] + y.v[i]
        }
        for i in 0..<k-1 {
            carry = r.v[i] >> 8
            r.v[i+1] += carry
            r.v[i] &= 0xff
        }
        sc.reduce_add_sub(&r)
    }

    static func sc25519_sub_nored(_ r: inout sc, _ x: sc, _ y: sc) {
        var borrow: UInt32 = 0
        var t: UInt32
        for i in 0..<k {
            t = x.v[i] - y.v[i] - borrow
            r.v[i] = t & 0xff
            borrow = (t >> 8) & 1
        }
    }

    static func sc25519_mul(_ r: inout sc, _ x: sc, _ y: sc) {
        var t = [UInt32](repeating: 0, count: k*2)

        for i in 0..<k {
            for j in 0..<k {
                t[i+j] += x.v[i] * y.v[j]
            }
        }

        /* Reduce coefficients */
        for i in 0..<2*k-1 {
            let carry = t[i] >> 8
            t[i+1] += carry
            t[i] &= 0xff
        }

        sc.barrett_reduce(&r, t)
    }

    static func sc25519_mul_shortsc(_ r: inout sc, _ x: sc, _ y: shortsc) {
        var t = sc()
        sc25519_from_shortsc(&t, y)
        sc25519_mul(&r, x, t)
    }

    // divide to 3bits
    // 3 * 85 = 255
    static func sc25519_window3(_ r: inout [Int8] /* 85 */, _ s: sc) {
        assert(r.count == 85)
        for i in 0..<10 {
            r[8*i+0]  = Int8(bitPattern: UInt8(s.v[3*i+0]       & 7))
            r[8*i+1]  = Int8(bitPattern: UInt8((s.v[3*i+0] >> 3) & 7))
            r[8*i+2]  = Int8(bitPattern: UInt8((s.v[3*i+0] >> 6) & 7))
            r[8*i+2] ^= Int8(bitPattern: UInt8((s.v[3*i+1] << 2) & 7))
            r[8*i+3]  = Int8(bitPattern: UInt8((s.v[3*i+1] >> 1) & 7))
            r[8*i+4]  = Int8(bitPattern: UInt8((s.v[3*i+1] >> 4) & 7))
            r[8*i+5]  = Int8(bitPattern: UInt8((s.v[3*i+1] >> 7) & 7))
            r[8*i+5] ^= Int8(bitPattern: UInt8((s.v[3*i+2] << 1) & 7))
            r[8*i+6]  = Int8(bitPattern: UInt8((s.v[3*i+2] >> 2) & 7))
            r[8*i+7]  = Int8(bitPattern: UInt8((s.v[3*i+2] >> 5) & 7))
        }
        let i = 10
        r[8*i+0]  =  Int8(bitPattern: UInt8(s.v[3*i+0]       & 7))
        r[8*i+1]  = Int8(bitPattern: UInt8((s.v[3*i+0] >> 3) & 7))
        r[8*i+2]  = Int8(bitPattern: UInt8((s.v[3*i+0] >> 6) & 7))
        r[8*i+2] ^= Int8(bitPattern: UInt8((s.v[3*i+1] << 2) & 7))
        r[8*i+3]  = Int8(bitPattern: UInt8((s.v[3*i+1] >> 1) & 7))
        r[8*i+4]  = Int8(bitPattern: UInt8((s.v[3*i+1] >> 4) & 7))

        /* Making it signed */
        var carry: Int8 = 0
        for i in 0..<84 {
            r[i] += carry
            r[i+1] += (r[i] >> 3)
            r[i] &= 7
            carry = r[i] >> 2
            let vv: Int16 = Int16(r[i]) - Int16(carry<<3)
            assert(vv >= -128 && vv <= 127)
            r[i] = Int8(vv)
        }
        r[84] += Int8(carry)
    }

    // scalar is less than 2^255 - 19, so 256bit value always zero.
    static func sc25519_2interleave2(_ r: inout [UInt8] /* 127 */, _ s1: sc, _ s2: sc) {
        assert(r.count == 127)
        for i in 0..<31 {
            let a1 = UInt8(s1.v[i] & 0xff)
            let a2 = UInt8(s2.v[i] & 0xff)
            // 8bits = 2bits * 4
            // s2 s1
            r[4*i]   = ((a1 >> 0) & 3) ^ (((a2 >> 0) & 3) << 2)
            r[4*i+1] = ((a1 >> 2) & 3) ^ (((a2 >> 2) & 3) << 2)
            r[4*i+2] = ((a1 >> 4) & 3) ^ (((a2 >> 4) & 3) << 2)
            r[4*i+3] = ((a1 >> 6) & 3) ^ (((a2 >> 6) & 3) << 2)
        }

        let b1 = UInt8(s1.v[31] & 0xff)
        let b2 = UInt8(s2.v[31] & 0xff)
        r[124] = ((b1 >> 0) & 3) ^ (((b2 >> 0) & 3) << 2)
        r[125] = ((b1 >> 2) & 3) ^ (((b2 >> 2) & 3) << 2)
        r[126] = ((b1 >> 4) & 3) ^ (((b2 >> 4) & 3) << 2)
    }
}

// field element
struct fe: CustomDebugStringConvertible {
    // WINDOWSIZE = 1, 8bit * 32 = 256bit
    // val = 2^(31*8) * v[31]
    //     + 2^(30*8) * v[30]
    //     + ..
    //     + 2^(2*8) * v[2]
    //     + 2^(1*8) * v[1]
    //     + 2^(0*8) * v[0]
    public var v: [UInt32] // size:32

    public var debugDescription: String {
        return v.map({ String(format: "%d ", $0)}).joined()
    }

    public init() {
        v = [UInt32](repeating: 0, count: 32)
    }

    public init(_ v: [UInt32]) {
        assert(v.count == 32)
        self.v = v
    }

    /* 16-bit inputs */
    static func equal(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return a == b ? 1 : 0
    }

    // greater equal
    /* 16-bit inputs */
    static func ge(_ a: UInt32, _ b: UInt32) -> UInt32 {
        return a >= b ? 1 : 0
    }

    // 19 * a = (2^4 + 2^1 + 2^0) * a
    static func times19(_ a: UInt32) -> UInt32 {
        return (a << 4) + (a << 1) + a
    }

    // 38 * a = (2^5 + 2^2 + 2^1) * a
    static func times38(_ a: UInt32) -> UInt32 {
        return (a << 5) + (a << 2) + (a << 1)
    }

    // q = 2^255 - 19 = 2^(31*8)*(2^7) - 19
    // 7fff ffff ffff ffff ffff ffff ffff ffff
    // ffff ffff ffff ffff ffff ffff ffff ffed
    // 0x7f = 0111 1111 = 2^7-1
    // 0xff = 1111 1111 = 2^8-1
    static func reduce_add_sub(_ r: inout fe) {
        var t: UInt32
        var s: UInt32
        // 32bit / 8bit = 4
        for _ in 0..<4 {
            // use q = 2^(31*8)*(2^7) - 19
            t = r.v[31] >> 7
            r.v[31] &= 0x7f
            t = times19(t)
            r.v[0] += t
            // move up
            for i in 0..<31 {
                s = r.v[i] >> 8
                r.v[i+1] += s
                r.v[i] &= 0xff
            }
        }
    }

    static func reduce_mul(_ r: inout fe) {
        var t: UInt32
        var s: UInt32
        for _ in 0..<2 {
            // use q = 2^(31*8)*(2^7) - 19
            t = r.v[31] >> 7
            r.v[31] &= 0x7f
            t = times19(t)
            r.v[0] += t
            // move up
            for i in 0..<31 {
                s = r.v[i] >> 8
                r.v[i+1] += s
                r.v[i] &= 0xff
            }
        }
    }

    /// reduction modulo 2^255-19
    /// 0x7f = 127
    /// 0xff = 255
    /// 0xed = 237
    static func fe25519_freeze(_ r: inout fe) {
        assert(r.v[31] <= 0xff)
        var m: UInt32 = equal(r.v[31], 127)
        for i in stride(from: 30, to: 0, by: -1) {
            m &= equal(r.v[i], 255)
        }
        m &= ge(r.v[0], 237)
        // Here if value is greater than q,  m is 1 or 0.
        m = UInt32(bitPattern: Int32(m) * -1)
        // m is 0xffffffff or 0x0

        r.v[31] -= (m&127)
        for i in stride(from: 30, to: 0, by: -1) {
            r.v[i] -= m&255
        }
        r.v[0] -= m&237
    }

    static func fe25519_unpack(_ r: inout fe, _ x: [UInt8]/* 32 */) {
        assert(x.count == 32)
        for i in 0..<32 {
            r.v[i] = UInt32(x[i])
        }
        r.v[31] &= 127 // remove parity
    }

    /// Assumes input x being reduced mod 2^255
    static func fe25519_pack(_ r: inout [UInt8] /* 32 or more */, _ x: fe) {
        assert(r.count >= 32)
        var y = x
        fe.fe25519_freeze(&y)
        for i in 0..<32 {
            r[i] = UInt8(y.v[i])
        }
    }

    /// freeze input before calling iszero
    static func fe25519_iszero(_ x: fe) -> Bool {
        var t = x
        fe.fe25519_freeze(&t)
        var r = fe.equal(t.v[0], 0)
        for i in 1..<32 {
            r &= fe.equal(t.v[i], 0)
        }
        return r != 0
    }

    /// is equal after freeze
    static func fe25519_iseq_vartime(_ x: fe, _ y: fe) -> Bool {
        var t1 = x
        var t2 = y
        fe.fe25519_freeze(&t1)
        fe.fe25519_freeze(&t2)
        for i in 0..<32 {
            if t1.v[i] != t2.v[i] {
                return false
            }
        }
        return true
    }

    /// conditional move
    static func fe25519_cmov(_ r: inout fe, _ x: fe, _ b: UInt8) {
        let mask = UInt32(bitPattern: Int32(b) * -1)
        for i in 0..<32 {
            // ^ means xor
            r.v[i] ^= mask & (x.v[i] ^ r.v[i])
        }
    }

    /// odd:1 even:0
    static func fe25519_getparity(_ x: fe) -> UInt8 {
        var t = x
        fe.fe25519_freeze(&t)
        return UInt8(t.v[0] & 1)
    }

    /// r = 1
    static func fe25519_setone(_ r: inout fe) {
        r.v[0] = 1
        for i in 1..<32 {
            r.v[i] = 0
        }
    }

    /// r = 0
    static func fe25519_setzero(_ r: inout fe) {
        for i in 0..<32 {
            r.v[i] = 0
        }
    }

    /// r = -x
    static func fe25519_neg(_ r: inout fe, _ x: fe) {
        var t = fe()
        for i in 0..<32 {
            t.v[i] = x.v[i]
        }
        fe25519_setzero(&r)
        fe25519_sub(&r, r, t)
    }

    /// r = x + y
    static func fe25519_add(_ r: inout fe, _ x: fe, _ y: fe) {
        for i in 0..<32 {
            r.v[i] = x.v[i] + y.v[i]
        }
        fe.reduce_add_sub(&r)
    }

    ///  r = x - y
    ///  q = 2 ** 255 - 19
    ///  7fff ffff ffff ffff ffff ffff ffff ffff
    ///  ffff ffff ffff ffff ffff ffff ffff ffed
    ///  2 * 7f = fe
    ///  2 * ff = 1fe
    ///  2 * ed = 1da
    /// @note result is reduced
    static func fe25519_sub(_ r: inout fe, _ x: fe, _ y: fe) {
        // t = 2 * q + x
        var t = [UInt32](repeating: 0, count: 32)
        t[0] = x.v[0] + 0x1da    // LSB
        for i in 1..<31 { t[i] = x.v[i] + 0x1fe }
        t[31] = x.v[31] + 0xfe    // MSB
        // r = t - y
        for i in 0..<32 { r.v[i] = t[i] - y.v[i] }
        fe.reduce_add_sub(&r)
    }

    /// r = x * y
    static func fe25519_mul(_ r: inout fe, _ x: fe, _ y: fe) {
        var t = [UInt32](repeating: 0, count: 63)

        for i in 0..<32 {
            for j in 0..<32 {
                t[i+j] += x.v[i] * y.v[j]
            }
        }

        // 2q = 2^256 - 2*19
        // so 2^256 = 2*19
        for i in 32..<63 {
            r.v[i-32] = t[i-32] + fe.times38(t[i])
        }
        r.v[31] = t[31] /* result now in r[0]...r[31] */

        fe.reduce_mul(&r)
    }

    /// r = x^2
    static func fe25519_square(_ r: inout fe, _ x: fe) {
        fe25519_mul(&r, x, x)
    }

    /// r = 1/x
    /// q = 2^255-19
    /// 1/a = a^(q-2)
    /// q-2 = 2^255-21
    static func fe25519_invert(_ r: inout fe, _ x: fe) {
        var z2 = fe()
        var z9 = fe()
        var z11 = fe()
        var z2_5_0 = fe()
        var z2_10_0 = fe()
        var z2_20_0 = fe()
        var z2_50_0 = fe()
        var z2_100_0 = fe()
        var t0 = fe()
        var t1 = fe()

        /* 2 */ fe25519_square(&z2, x)
        /* 4 */ fe25519_square(&t1, z2)
        /* 8 */ fe25519_square(&t0, t1)
        /* 9 */ fe25519_mul(&z9, t0, x)
        /* 11 */ fe25519_mul(&z11, z9, z2)
        /* 22 */ fe25519_square(&t0, z11)
        /* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0, t0, z9)

        /* 2^6 - 2^1 */ fe25519_square(&t0, z2_5_0)
        /* 2^7 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^8 - 2^3 */ fe25519_square(&t0, t1)
        /* 2^9 - 2^4 */ fe25519_square(&t1, t0)
        /* 2^10 - 2^5 */ fe25519_square(&t0, t1)
        /* 2^10 - 2^0 */ fe25519_mul(&z2_10_0, t0, z2_5_0)

        /* 2^11 - 2^1 */ fe25519_square(&t0, z2_10_0)
        /* 2^12 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^20 - 2^10 */ for _ in stride(from: 2, to: 10, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^20 - 2^0 */ fe25519_mul(&z2_20_0, t1, z2_10_0)

        /* 2^21 - 2^1 */ fe25519_square(&t0, z2_20_0)
        /* 2^22 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^40 - 2^20 */ for _ in stride(from: 2, to: 20, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^40 - 2^0 */ fe25519_mul(&t0, t1, z2_20_0)

        /* 2^41 - 2^1 */ fe25519_square(&t1, t0)
        /* 2^42 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^50 - 2^10 */ for _ in stride(from: 2, to: 10, by: 2) { fe25519_square(&t1, t0); fe25519_square(&t0, t1) }
        /* 2^50 - 2^0 */ fe25519_mul(&z2_50_0, t0, z2_10_0)

        /* 2^51 - 2^1 */ fe25519_square(&t0, z2_50_0)
        /* 2^52 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^100 - 2^50 */ for _ in stride(from: 2, to: 50, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^100 - 2^0 */ fe25519_mul(&z2_100_0, t1, z2_50_0)

        /* 2^101 - 2^1 */ fe25519_square(&t1, z2_100_0)
        /* 2^102 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^200 - 2^100 */ for _ in stride(from: 2, to: 100, by: 2) { fe25519_square(&t1, t0); fe25519_square(&t0, t1) }
        /* 2^200 - 2^0 */ fe25519_mul(&t1, t0, z2_100_0)

        /* 2^201 - 2^1 */ fe25519_square(&t0, t1)
        /* 2^202 - 2^2 */ fe25519_square(&t1, t0)
        /* 2^250 - 2^50 */ for _ in stride(from: 2, to: 50, by: 2) { fe25519_square(&t0, t1); fe25519_square(&t1, t0) }
        /* 2^250 - 2^0 */ fe25519_mul(&t0, t1, z2_50_0)

        /* 2^251 - 2^1 */ fe25519_square(&t1, t0)
        /* 2^252 - 2^2 */ fe25519_square(&t0, t1)
        /* 2^253 - 2^3 */ fe25519_square(&t1, t0)
        /* 2^254 - 2^4 */ fe25519_square(&t0, t1)
        /* 2^255 - 2^5 */ fe25519_square(&t1, t0)
        /* 2^255 - 21 */ fe25519_mul(&r, t1, z11)
    }

    /// q = 2^255-19
    /// (q-5)/8 = 2^252 - 3
    /// r = x ^ (2^252 - 3)
    static func fe25519_pow2523(_ r: inout fe, _ x: fe) {
        var z2 = fe()
        var z9 = fe()
        var z11 = fe()
        var z2_5_0 = fe()
        var z2_10_0 = fe()
        var z2_20_0 = fe()
        var z2_50_0 = fe()
        var z2_100_0 = fe()
        var t = fe()

        /* 2 */ fe25519_square(&z2, x)
        /* 4 */ fe25519_square(&t, z2)
        /* 8 */ fe25519_square(&t, t)
        /* 9 */ fe25519_mul(&z9, t, x)
        /* 11 */ fe25519_mul(&z11, z9, z2)
        /* 22 */ fe25519_square(&t, z11)
        /* 2^5 - 2^0 = 31 */ fe25519_mul(&z2_5_0, t, z9)

        /* 2^6 - 2^1 */ fe25519_square(&t, z2_5_0)
        /* 2^10 - 2^5 */ for _ in 1..<5 { fe25519_square(&t, t) }
        /* 2^10 - 2^0 */ fe25519_mul(&z2_10_0, t, z2_5_0)

        /* 2^11 - 2^1 */ fe25519_square(&t, z2_10_0)
        /* 2^20 - 2^10 */ for _ in 1..<10 { fe25519_square(&t, t) }
        /* 2^20 - 2^0 */ fe25519_mul(&z2_20_0, t, z2_10_0)

        /* 2^21 - 2^1 */ fe25519_square(&t, z2_20_0)
        /* 2^40 - 2^20 */ for _ in 1..<20 { fe25519_square(&t, t) }
        /* 2^40 - 2^0 */ fe25519_mul(&t, t, z2_20_0)

        /* 2^41 - 2^1 */ fe25519_square(&t, t)
        /* 2^50 - 2^10 */ for _ in 1..<10 { fe25519_square(&t, t) }
        /* 2^50 - 2^0 */ fe25519_mul(&z2_50_0, t, z2_10_0)

        /* 2^51 - 2^1 */ fe25519_square(&t, z2_50_0)
        /* 2^100 - 2^50 */ for _ in 1..<50 { fe25519_square(&t, t) }
        /* 2^100 - 2^0 */ fe25519_mul(&z2_100_0, t, z2_50_0)

        /* 2^101 - 2^1 */ fe25519_square(&t, z2_100_0)
        /* 2^200 - 2^100 */ for _ in 1..<100 { fe25519_square(&t, t) }
        /* 2^200 - 2^0 */ fe25519_mul(&t, t, z2_100_0)

        /* 2^201 - 2^1 */ fe25519_square(&t, t)
        /* 2^250 - 2^50 */ for _ in 1..<50 { fe25519_square(&t, t) }
        /* 2^250 - 2^0 */ fe25519_mul(&t, t, z2_50_0)

        /* 2^251 - 2^1 */ fe25519_square(&t, t)
        /* 2^252 - 2^2 */ fe25519_square(&t, t)
        /* 2^252 - 3 */ fe25519_mul(&r, t, x)
    }
}
