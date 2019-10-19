//
//  DogeTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

extension String.adamantLocalized {
    struct dogeTransaction {
        static func recipients(_ recipients: Int) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Doge.TransactionDetails.RecipientsFormat", comment: "DogeTransaction: amount of recipients, if more than one."), recipients)
        }
        
        static func senders(_ senders: Int) -> String {
            return String.localizedStringWithFormat(NSLocalizedString("Doge.TransactionDetails.SendersFormat", comment: "DogeTransaction: amount of senders, if more than one."), senders)
        }
        
        private init() {}
    }
}

class DogeTransaction: BaseBtcTransaction {
    override class var defaultCurrencySymbol: String? { return DogeWalletService.currencySymbol }
}

// MARK: - Sample Json

/* Doge Transaction

{
    "txid": "5879c2257fdd0b44e2e66e3ffca4bb6ba77c8e5f6773f3c7d7162da9b3237b5a",
    "version": 1,
    "locktime": 0,
    "vin": [],
    "vout": [],
    "blockhash": "49c0f690455804aa0c96cb8e08ede058ee853ef216958656315ed76e115b0fe4",
    "confirmations": 99,
    "time": 1554298220,
    "blocktime": 1554298220,
    "valueOut": 1855.6647,
    "size": 226,
    "valueIn": 1856.6647,
    "fees": 1,
    "firstSeenTs": 1554298214
}
 
new transaction:
{
    "txid": "60cd612335c9797ea67689b9cde4a41e20c20c1b96eb0731c59c5b0eab8bad31",
    "version": 1,
    "locktime": 0,
    "vin": [],
    "vout": [],
    "valueOut": 283,
    "size": 225,
    "valueIn": 284,
    "fees": 1
}
 
*/

/* Inputs
 
{
    "txid": "3f4fa05bef67b1aacc0392fd5c3be3f94c991394166bc12ca73df28b63fe0aab",
    "vout": 0,
    "scriptSig": {
        "asm": "0 3045022100d5b2470b6eb2f1933506f80bf5158526fc8262d2f29fd2c217f7deb8699fdd3d02205ae2d07e04849af40d252526418da9d0b1995f796463c9a2e73e2a3621a6d64901 3044022026f93ee27fe6fbd6ca4edd01a842881f96998af5012831e0003c5c8907ee31a902206d61ebeed160c4dae8853438d916c494867c57eaa45c6ba9351e4a212e26a4d801 522103ce2fb71cceec5c4e18ab8907ebd5c2a5dbbbed116088ae9f67f2067d3f698bb02103693c5397bade9b433e80bce0785457f9899a960ad70f159f09006e31e79f690c52ae",
        "hex": "00483045022100d5b2470b6eb2f1933506f80bf5158526fc8262d2f29fd2c217f7deb8699fdd3d02205ae2d07e04849af40d252526418da9d0b1995f796463c9a2e73e2a3621a6d64901473044022026f93ee27fe6fbd6ca4edd01a842881f96998af5012831e0003c5c8907ee31a902206d61ebeed160c4dae8853438d916c494867c57eaa45c6ba9351e4a212e26a4d80147522103ce2fb71cceec5c4e18ab8907ebd5c2a5dbbbed116088ae9f67f2067d3f698bb02103693c5397bade9b433e80bce0785457f9899a960ad70f159f09006e31e79f690c52ae"
    },
    "sequence": 4294967295,
    "n": 0,
    "addr": "A6qMXXr5WdroSeLRZVwRwbiPBVP8gBGS6W",
    "valueSat": 99800000000,
    "value": 998,
    "doubleSpentTxID": null
}
*/

/* Outputs
{
    "value": "172436.00000000",
    "n": 1,
    "scriptPubKey": {
        "asm": "OP_HASH160 9def6388804f6e46700059747c0218d4108a76f3 OP_EQUAL",
        "hex": "a9149def6388804f6e46700059747c0218d4108a76f387",
        "reqSigs": 1,
        "type": "scripthash",
        "addresses": [
             "A6qMXXr5WdroSeLRZVwRwbiPBVP8gBGS6W"
        ]
    },
    "spentTxId": "966342801119bdd5601823df2a98e9a0482e6b6cd3a69c84c0d8d7cb120caa4d",
    "spentIndex": 2,
    "spentTs": 1554229560
}
*/
