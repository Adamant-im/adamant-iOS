//
//  SegWitBech32.swift
//
//  Created by Evolution Group Ltd on 12.02.2018.
//  Copyright © 2018 Evolution Group Ltd. All rights reserved.
//

//  Base32 address format for native v0-16 witness outputs implementation
//  https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
//  Inspired by Pieter Wuille C++ implementation

import Foundation

/// Segregated Witness Address encoder/decoder
public class SegWitBech32 {
    /// Convert from one power-of-2 number base to another
    private static func convertBits(from: Int, to: Int, pad: Bool, idata: Data) throws -> Data {
        var acc: Int = 0
        var bits: Int = 0
        let maxv: Int = (1 << to) - 1
        let maxAcc: Int = (1 << (from + to - 1)) - 1
        var odata = Data()
        for ibyte in idata {
            acc = ((acc << from) | Int(ibyte)) & maxAcc
            bits += from
            while bits >= to {
                bits -= to
                odata.append(UInt8((acc >> bits) & maxv))
            }
        }
        if pad {
            if bits != 0 {
                odata.append(UInt8((acc << (to - bits)) & maxv))
            }
        } else if (bits >= from || ((acc << (to - bits)) & maxv) != 0) {
            throw CoderError.bitsConversionFailed
        }
        return odata
    }
    
    /// Decode segwit address
    public static func decode(hrp: String, addr: String, hasAdvanced: Bool = true) throws -> (version: UInt8, program: Data) {
        let dec = try Bech32.shared.decode(addr)
        guard dec.hrp == hrp else {
            throw CoderError.hrpMismatch(dec.hrp, hrp)
        }
        guard dec.checksum.count >= 1 else {
            throw CoderError.checksumSizeTooLow
        }
        let idata = (hasAdvanced ? dec.checksum.advanced(by: 1) : dec.checksum)
        let conv = try convertBits(from: 5, to: 8, pad: false, idata: idata)
        guard conv.count >= 2 && conv.count <= 40 else {
            throw CoderError.dataSizeMismatch(conv.count)
        }
        guard dec.checksum[0] <= 16 else {
            throw CoderError.segwitVersionNotSupported(dec.checksum[0])
        }
        if dec.checksum[0] == 0 && conv.count != 20 && conv.count != 32 {
            throw CoderError.segwitV0ProgramSizeMismatch(conv.count)
        }
        if (dec.checksum[0] == 0 && dec.encoding != .bech32) || (dec.checksum[0] != 0 && dec.encoding != .bech32m) {
            throw CoderError.segwitVersionAndEncodingMismatch
        }
        return (dec.checksum[0], conv)
    }
    
    /// Encode segwit address
    public static func encode(hrp: String, version: UInt8, program: Data, encoding: Bech32.Encoding) throws -> String {
        var enc = Data([version])
        enc.append(try convertBits(from: 8, to: 5, pad: true, idata: program))
        let result = Bech32.shared.encode(hrp, values: enc, encoding: encoding)
        guard let _ = try? decode(hrp: hrp, addr: result) else {
            throw CoderError.encodingCheckFailed
        }
        return result
    }

    public init() {}

}

extension SegWitBech32 {
    public enum CoderError: LocalizedError {
        case bitsConversionFailed
        case hrpMismatch(String, String)
        case checksumSizeTooLow
        
        case dataSizeMismatch(Int)
        case segwitVersionNotSupported(UInt8)
        case segwitV0ProgramSizeMismatch(Int)
        case segwitVersionAndEncodingMismatch

        case encodingCheckFailed
        
        public var errorDescription: String? {
            switch self {
            case .bitsConversionFailed:
                return "Failed to perform bits conversion"
            case .checksumSizeTooLow:
                return "Checksum size is too low"
            case .dataSizeMismatch(let size):
                return "Program size \(size) does not meet required range 2...40"
            case .encodingCheckFailed:
                return "Failed to check result after encoding"
            case .hrpMismatch(let got, let expected):
                return "Human-readable-part \"\(got)\" does not match requested \"\(expected)\""
            case .segwitV0ProgramSizeMismatch(let size):
                return "Segwit program size \(size) does not meet version 0 requirements"
            case .segwitVersionNotSupported(let version):
                return "Segwit version \(version) is not supported by this decoder"
            case .segwitVersionAndEncodingMismatch:
                return "Wrong encoding is used for the Segwit version being used"
            }
        }
    }
}
