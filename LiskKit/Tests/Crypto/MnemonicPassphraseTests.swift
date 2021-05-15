//
//  MnemonicPassphraseTests.swift
//  LiskTests
//
//  Created by Andrew Barba on 1/26/18.
//

import XCTest
@testable import LiskKit

class MnemonicPassphraseTests: LiskTestCase {

    func testPassphrases() {
        var passphrases = Set<String>()
        for _ in 0...100_000 {
            let passphrase = MnemonicPassphrase().passphrase
            XCTAssertFalse(passphrases.contains(passphrase))
            passphrases.insert(passphrase)
        }
    }
}
