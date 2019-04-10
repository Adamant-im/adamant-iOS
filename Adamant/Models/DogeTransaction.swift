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

struct DogeTransaction: TransactionDetails {
    static var defaultCurrencySymbol: String? { return "DOGE" }
    
    let txId: String
    let dateValue: Date?
    let blockValue: String?
    
    let senderAddress: String
    let recipientAddress: String
    
    let amountValue: Decimal
    let feeValue: Decimal?
    let confirmationsValue: String?
    
    let isOutgoing: Bool
    let transactionStatus: TransactionStatus?
}


// MARK: - Raw Doge Transaction, for easy parsing
struct DogeRawTransaction {
    let txId: String
    let date: Date?
    
    let valueIn: Decimal
    let valueOut: Decimal
    let fee: Decimal
    
    let confirmations: Int?
    let blockHash: String?
    
    let inputs: [DogeInput]
    let outputs: [DogeOutput]
    
    func asDogeTransaction(for address: String, blockId: String? = nil) -> DogeTransaction {
        // MARK: Known values
        let confirmationsValue: String?
        let transactionStatus: TransactionStatus
        
        if let confirmations = confirmations {
            confirmationsValue = String(confirmations)
            transactionStatus = confirmations > 0 ? .success : .pending
        } else {
            confirmationsValue = nil
            transactionStatus = .pending
        }
        
        // Transfers
        var myInputs = inputs.filter { $0.sender == address }
        var myOutputs = outputs.filter { $0.addresses.contains(address) }
        
        var totalInputsValue = myInputs.map { $0.value }.reduce(0, +) - fee
        var totalOutputsValue = myOutputs.map { $0.value }.reduce(0, +)
        
        if totalInputsValue > totalOutputsValue {
            while let out = myOutputs.first {
                totalInputsValue -= out.value
                totalOutputsValue -= out.value
                
                myOutputs.removeFirst()
            }
        }
        
        if totalInputsValue < totalOutputsValue {
            while let i = myInputs.first {
                totalInputsValue -= i.value
                totalOutputsValue -= i.value
                
                myInputs.removeFirst()
            }
        }
        
        let senders = Set(inputs.map { $0.sender }.filter { $0 != address })
        let recipients = Set(outputs.compactMap { $0.addresses.first }.filter { $0 != address })
        
        // MARK: Inputs
        if myInputs.count > 0 {
            let recipient: String
            if recipients.count == 1, let name = recipients.first {
                recipient = name
            } else {
                recipient = String.adamantLocalized.dogeTransaction.recipients(recipients.count)
            }
            
            let inputTransaction =  DogeTransaction(txId: txId,
                                                    dateValue: date,
                                                    blockValue: blockId,
                                                    senderAddress: address,
                                                    recipientAddress: recipient,
                                                    amountValue: totalInputsValue,
                                                    feeValue: fee,
                                                    confirmationsValue: confirmationsValue,
                                                    isOutgoing: true,
                                                    transactionStatus: transactionStatus)
            
            return inputTransaction
        }
        
        // MARK: Outputs
        let sender: String
        if senders.count == 1, let name = senders.first {
            sender = name
        } else {
            sender = String.adamantLocalized.dogeTransaction.senders(senders.count)
        }
        
        let outputTransaction = DogeTransaction(txId: txId,
                                                dateValue: date,
                                                blockValue: blockId,
                                                senderAddress: sender,
                                                recipientAddress: address,
                                                amountValue: totalOutputsValue,
                                                feeValue: fee,
                                                confirmationsValue: confirmationsValue,
                                                isOutgoing: false,
                                                transactionStatus: transactionStatus)
        
        return outputTransaction
    }
}

extension DogeRawTransaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case date = "time"
        case valueIn
        case valueOut
        case fee = "fees"
        case confirmations
        case blockHash = "blockhash"
        case inputs = "vin"
        case outputs = "vout"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // MARK: Required
        self.txId = try container.decode(String.self, forKey: .txId)
        self.valueIn = try container.decode(Decimal.self, forKey: .valueIn)
        self.valueOut = try container.decode(Decimal.self, forKey: .valueOut)
        self.fee = try container.decode(Decimal.self, forKey: .fee)
        
        // MARK: Optionals for new transactions
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .date) {
            self.date = Date(timeIntervalSince1970: timeInterval)
        } else {
            self.date = nil
        }
        
        self.confirmations = try? container.decode(Int.self, forKey: .confirmations)
        self.blockHash = try? container.decode(String.self, forKey: .blockHash)
        
        // MARK: Inputs & Outputs
        
        self.inputs = try container.decode([DogeInput].self, forKey: .inputs)
        self.outputs = try container.decode([DogeOutput].self, forKey: .outputs)
    }
}


// MARK: Doge internal
struct DogeInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case sender = "addr"
        case value
        case txId = "txid"
        case vOut = "vout"
    }
    
    let sender: String
    let value: Decimal
    let txId: String
    let vOut: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sender = try container.decode(String.self, forKey: .sender)
        self.value = try container.decode(Decimal.self, forKey: .value)
        self.txId = try container.decode(String.self, forKey: .txId)
        self.vOut = try container.decode(Int.self, forKey: .vOut)
    }
}

struct DogeOutput: Decodable {
    enum CodingKeys: String, CodingKey {
        case signature = "scriptPubKey"
        case value
        case spentTxId
        case spentIndex
    }
    
    enum SignatureCodingKeys: String, CodingKey {
        case addresses
    }
    
    let addresses: [String]
    let value: Decimal
    let spentTxId: String?
    let spentIndex: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let signatureContainer = try container.nestedContainer(keyedBy: SignatureCodingKeys.self, forKey: .signature)
        self.addresses = try signatureContainer.decode([String].self, forKey: .addresses)
        
        if let raw = try? container.decode(String.self, forKey: .value), let value = Decimal(string: raw) {
            self.value = value
        } else {
            self.value = 0
        }
        
        self.spentTxId = try? container.decode(String.self, forKey: .spentTxId)
        self.spentIndex = try? container.decode(Int.self, forKey: .spentIndex)
    }
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
