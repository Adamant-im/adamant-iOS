//
//  BTCRawTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 25/05/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation

// MARK: - Raw BTC Transaction, for easy parsing. Support BTC Style transaction like BTC, Doge and Dash
struct BTCRawTransaction {
    let txId: String
    let date: Date?
    
    let valueIn: Decimal
    let valueOut: Decimal
    let fee: Decimal
    
    let confirmations: Int?
    let blockHash: String?
    
    let inputs: [BTCInput]
    let outputs: [BTCOutput]

    let isDoubleSpend: Bool
    
    func asBtcTransaction<T: BaseBtcTransaction>(_ as:T.Type, for address: String, blockId: String? = nil) -> T {
        // MARK: Known values
        let confirmationsValue: String?
        let transactionStatus: TransactionStatus
        
        if let confirmations = confirmations {
            confirmationsValue = String(confirmations)
            transactionStatus = confirmations > 0 ? .success : .pending
        } else {
            confirmationsValue = nil
            transactionStatus = .notInitiated
        }
        
        // Transfers
        var myInputs = inputs.filter { $0.sender == address }
        var myOutputs = outputs.filter { $0.addresses.contains(address) }
        
        var totalInputsValue = myInputs.map { $0.value }.reduce(0, +) - fee
        var totalOutputsValue = myOutputs.map { $0.value }.reduce(0, +)
        
        if totalInputsValue == totalOutputsValue {
            totalInputsValue = 0
            totalOutputsValue = 0
        }
        
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
        
        let senders = Set(inputs.map { $0.sender })
        let recipients = Set(outputs.compactMap { $0.addresses.first })
        
        let sender: String
        let recipient: String
        
        if senders.count == 1 {
            sender = senders.first!
        } else {
            let filtered = senders.filter { $0 != address }
            
            if filtered.count == 1 {
                sender = filtered.first!
            } else {
                sender = String.adamant.dogeTransaction.senders(senders.count)
            }
        }
        
        if recipients.count == 1 {
            recipient = recipients.first!
        } else {
            let filtered = recipients.filter { $0 != address }
            
            if filtered.count == 1 {
                recipient = filtered.first!
            } else {
                recipient = String.adamant.dogeTransaction.recipients(recipients.count)
            }
        }
        
        // MARK: Inputs
        if myInputs.count > 0 {
            let inputTransaction =  T(txId: txId,
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
        let outputTransaction = T(txId: txId,
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

extension BTCRawTransaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case hash = "hash"
        case possibleDoubleSpend = "possibleDoubleSpend"
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
        txId = try container.decode(String.self, forKey: .txId)
        
        let possibleDoubleSpend = (try? container.decode(Bool.self, forKey: .possibleDoubleSpend)) ?? false
        
        // MARK: Optionals for new transactions
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .date) {
            date = Date(timeIntervalSince1970: timeInterval)
        } else {
            date = nil
        }
        
        guard !possibleDoubleSpend else {
            isDoubleSpend = true
            valueIn = 0
            valueOut = 0
            fee = 0
            confirmations = nil
            blockHash = nil
            inputs = []
            outputs = []
            return
        }
        
        confirmations = try? container.decode(Int.self, forKey: .confirmations)
        blockHash = try? container.decode(String.self, forKey: .blockHash)
        
        // MARK: Inputs & Outputs
        let rawInputs = try container.decode([BTCInput].self, forKey: .inputs)
        inputs = rawInputs.filter { !$0.sender.isEmpty }  // Filter incomplete transactions without sender
        outputs = try container.decode([BTCOutput].self, forKey: .outputs)
        
        if let rawValueIn = try? container.decode(Decimal.self, forKey: .valueIn),
           let rawValueOut = try? container.decode(Decimal.self, forKey: .valueOut) {
            valueIn = rawValueIn
            valueOut = rawValueOut
        } else {
            // Total In & Out. Can be null sometimes...
            if let raw = try? container.decode(Decimal.self, forKey: .valueIn) {
                valueIn = raw
            } else {
                valueIn = self.inputs.map { $0.value }.reduce(0, +)
            }

            if let raw = try? container.decode(Decimal.self, forKey: .valueOut) {
                valueOut = raw
            } else {
                valueOut = outputs.map { $0.value }.reduce(0, +)
            }
        }
        
        if let raw = try? container.decode(Decimal.self, forKey: .fee) {
            fee = raw
        } else {
            fee = valueIn - valueOut
        }
        
        isDoubleSpend = false
    }
}

// MARK: BTC internal
struct BTCInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case sender = "addr"
        case senderDash = "address"
        case value = "valueSat"
        case txId = "txid"
        case vOut = "vout"
    }
    
    let sender: String
    let value: Decimal
    let txId: String
    let vOut: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Incomplete inputs doesn't contains address. We will filter them out
        if let raw = try? container.decode(String.self, forKey: .sender) {
            self.sender = raw
        } else if let raw = try? container.decode(String.self, forKey: .senderDash) {
            // Completable with DASH
            self.sender = raw
        } else {
            self.sender = ""
        }
        
        self.txId = try container.decode(String.self, forKey: .txId)
        self.vOut = try container.decode(Int.self, forKey: .vOut)
        
        if let raw = try? container.decode(Decimal.self, forKey: .value) {
            self.value = Decimal(sign: .plus, exponent: DogeWalletService.currencyExponent, significand: raw)
        } else {
            self.value = 0
        }
    }
}

struct BTCOutput: Decodable {
    enum CodingKeys: String, CodingKey {
        case signature = "scriptPubKey"
        case value
        case valueSat
        case spentTxId
        case spentIndex
    }
    
    enum SignatureCodingKeys: String, CodingKey {
        case addresses
    }
    
    let addresses: [String]
    var value: Decimal
    let spentTxId: String?
    let spentIndex: Int?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let signatureContainer = try container.nestedContainer(keyedBy: SignatureCodingKeys.self, forKey: .signature)
        self.addresses = try signatureContainer.decode([String].self, forKey: .addresses)
        
        if let raw = try? container.decode(String.self, forKey: .value), let value = Decimal(string: raw) {
            self.value = value
        } else if let raw = try? container.decode(Decimal.self, forKey: .value) {
            self.value = raw
        } else {
            self.value = 0
        }
        
        if let raw = try? container.decode(String.self, forKey: .valueSat), let value = Decimal(string: raw) {
            self.value = Decimal(sign: .plus, exponent: DogeWalletService.currencyExponent, significand: value)
        } else if let raw = try? container.decode(Decimal.self, forKey: .valueSat) {
            self.value = Decimal(sign: .plus, exponent: DogeWalletService.currencyExponent, significand: raw)
        }
        
        self.spentTxId = try? container.decode(String.self, forKey: .spentTxId)
        self.spentIndex = try? container.decode(Int.self, forKey: .spentIndex)
    }
}
