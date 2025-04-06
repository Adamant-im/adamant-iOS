import XCTest

@testable import CommonKit

final class HexBytesTests: XCTestCase {
    func test_hexBytes_smallStringWithLettersAndDigits() {
        let input = "48656c6c6f"
        let expectedOutput: [UInt8] = [0x48, 0x65, 0x6c, 0x6c, 0x6f]
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_bigStringWithAllLettersAndAllDigits() {
        let input = "1234567890abcdef"
        let expectedOutput: [UInt8] = [0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef]
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_emptyString() {
        let input = ""
        let expectedOutput: [UInt8] = []
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_withEdgeHexValues() {
        let input = "00ff"
        let expectedOutput: [UInt8] = [0x00, 0xff]
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_withUppercaseLetters() {
        let input = "ABCDEF"
        let expectedOutput: [UInt8] = [0xAB, 0xCD, 0xEF]
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_replacesInvalidHexesWithZeros() {
        let input = "AXBXCDEF"
        let expectedOutput: [UInt8] = [0x00, 0x00, 0xCD, 0xEF]
        XCTAssertEqual(input.hexBytes(), expectedOutput)
    }

    func test_hexBytes_performance() {
        let input = String.init(repeating: "0123456789abcdef", count: 20000)

        measure {
            _ = input.hexBytes()
        }
    }
}
