//
//  BtcTransactionResponse.swift
//  Adamant
//
//  Created by Anton Boyarkin on 10.05.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

struct RawBtcTransactionResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case inputs = "vin"
        case outputs = "vout"
        case fee
        case status
    }
    
    let txId: String
    let inputs: [RawBtcInput]
    let outputs: [RawBtcOutput]
    let fee: Decimal
    let status: RawBtcStatus
}

struct RawBtcInput: Decodable {
    enum CodingKeys: String, CodingKey {
        case txId = "txid"
        case prevout
    }
    
    let txId: String
    let prevout: RawBtcOutput
}

struct RawBtcOutput: Decodable {
    enum CodingKeys: String, CodingKey {
        case address = "scriptpubkey_address"
        case value
    }

    let address: String
    let value: Decimal

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.address = try container.decode(String.self, forKey: .address)
        
        let raw = try container.decode(Decimal.self, forKey: .value)
        self.value = raw / BtcWalletService.multiplier
    }
}

struct RawBtcStatus: Decodable {
    enum CodingKeys: String, CodingKey {
        case confirmed
        case height = "block_height"
        case hash = "block_hash"
        case time = "block_time"
    }
    
    let confirmed: Bool
    let height: Decimal
    let hash: String
    let time: Decimal
}

extension RawBtcTransactionResponse {
    func asBtcTransaction<T: BaseBtcTransaction>(_ as:T.Type, for address: String, height: Decimal? = nil) -> T {
        let transactionStatus: TransactionStatus = status.confirmed ? .success : .pending

        let date = Date(timeIntervalSince1970: status.time.doubleValue)
        let fee = fee / BtcWalletService.multiplier

        let confirmationsValue: String?
        if let height = height {
            confirmationsValue = "\(height - status.height)"
        } else {
            confirmationsValue = nil
        }

        // Transfers
        var myInputs = inputs.filter { $0.prevout.address == address }
        var myOutputs = outputs.filter { $0.address == address }
        
        var totalInputsValue = myInputs.map { $0.prevout.value }.reduce(0, +) - fee
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
                totalInputsValue -= i.prevout.value
                totalOutputsValue -= i.prevout.value
                
                myInputs.removeFirst()
            }
        }
        
        let senders = Set(inputs.map { $0.prevout.address } )
        let recipients = Set(outputs.map { $0.address } )
        
        let sender: String
        let recipient: String
        
        if senders.count == 1 {
            sender = senders.first!
        } else {
            let filtered = senders.filter { $0 != address }
            
            if filtered.count == 1 {
                sender = filtered.first!
            } else {
                sender = String.adamantLocalized.dogeTransaction.senders(senders.count)
            }
        }
        
        if recipients.count == 1 {
            recipient = recipients.first!
        } else {
            let filtered = recipients.filter { $0 != address }
            
            if filtered.count == 1 {
                recipient = filtered.first!
            } else {
                recipient = String.adamantLocalized.dogeTransaction.recipients(recipients.count)
            }
        }
        
        
        // MARK: Inputs
        if myInputs.count > 0 {
            let inputTransaction =  T(txId: txId,
                                      dateValue: date,
                                      blockValue: status.hash,
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
                                  blockValue: status.hash,
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
