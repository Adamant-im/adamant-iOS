//
//  EthTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import struct BigInt.BigUInt

struct EthResponse {
    let status: Int
    let message: String
    let result: [EthTransaction]
}

// MARK: - Decodable
extension EthResponse: Decodable {
	enum CodingKeys: String, CodingKey {
		case status
		case message
		case result
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let raw = try? container.decode(String.self, forKey: .status), let status = Int(raw) {
			self.status = status
		} else {
			self.status = 0
		}
		
		message = (try? container.decode(String.self, forKey: .message)) ?? ""
		result = (try? container.decode([EthTransaction].self, forKey: .result)) ?? []
	}
}


// MARK: - Eth Transaction

enum TransactionReceiptStatus: String, Decodable {
    case fail = "0"
    case pass = "1"
    case unknown
}

struct EthTransaction {
	let date: Date
    let hash: String
    let value: BigUInt
    let from: String
    let to: String
    let gasUsed: BigUInt
    let gasPrice: BigUInt
    let confirmationsValue: String
    let isError: Bool
    let receiptStatus: TransactionReceiptStatus
    let blockNumber: UInt
	
    func formattedValue() -> String {
		if let formattedAmount = Web3.Utils.formatToEthereumUnits(value,
                                                                  toUnits: .eth,
                                                                  decimals: 8,
                                                                  fallbackToScientific: true),
			let amount = Double(formattedAmount) {
            return "\(amount) ETH"
        } else {
            return "\(value)"
        }
    }
}


// MARK: Decodable
extension EthTransaction: Decodable {
	enum CodingKeys: String, CodingKey {
		case date = "timeStamp"
		case hash
		case value
		case from
		case to
		case gasUsed
		case gasPrice
		case confirmations
		case isError
		case receiptStatus = "txreceipt_status"
		case blockNumber
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let unixTimeStamp = Double((try? container.decode(String.self, forKey: .date)) ?? "0") ?? 0
		date = Date(timeIntervalSince1970: unixTimeStamp)
		hash = (try? container.decode(String.self, forKey: .hash)) ?? ""
		value = BigUInt((try? container.decode(String.self, forKey: .value)) ?? "0") ?? BigUInt(0)
		from = (try? container.decode(String.self, forKey: .from)) ?? ""
		to = (try? container.decode(String.self, forKey: .to)) ?? ""
		gasUsed = BigUInt((try? container.decode(String.self, forKey: .gasUsed)) ?? "0") ?? BigUInt(0)
		gasPrice = BigUInt((try? container.decode(String.self, forKey: .gasPrice)) ?? "0") ?? BigUInt(0)
		confirmationsValue = (try? container.decode(String.self, forKey: .confirmations)) ?? "0"
		let isErrorStatus = Int((try? container.decode(String.self, forKey: .isError)) ?? "0") ?? 0
		isError = isErrorStatus == 1 ? true : false
		receiptStatus = (try? container.decode(TransactionReceiptStatus.self, forKey: .receiptStatus)) ?? .unknown
		blockNumber = UInt((try? container.decode(String.self, forKey: .blockNumber)) ?? "0") ?? 0
	}
}


// MARK: TransactionDetailsProtocol
extension EthTransaction: TransactionDetailsProtocol {
    var id: String {
        return self.hash
    }
    
    var senderAddress: String {
        return self.from
    }
    
    var recipientAddress: String {
        return self.to
    }
    
    var sentDate: Date {
        return self.date
    }
    
    var amountValue: Double {
        guard let string = Web3.Utils.formatToEthereumUnits(value, toUnits: .eth, decimals: 8), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var feeValue: Double {
        guard let string = Web3.Utils.formatToEthereumUnits((self.gasPrice * self.gasUsed), toUnits: .eth, decimals: 8), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var block: String {
        return "\(self.blockNumber)"
    }
    
    var showGoToExplorer: Bool {
        return true
    }
    
    var explorerUrl: URL? {
        return URL(string: "https://etherscan.io/tx/\(id)")
    }
    
    var showGoToChat: Bool {
        return false
    }
    
    var chatroom: Chatroom? {
        return nil
    }
    
    var currencyCode: String {
        return "ETH"
    }
}


// MARK: Sample JSON
/*
 {
	 "blockNumber":"3455267",
	 "timeStamp":"1529241530",
	 "hash":"0x9e2092aa9a278ebdd5cc4e37d626533ec1a480397c101add069817c0934cfa76",
	 "nonce":"561145",
	 "blockHash":"0xf828955a0911da4a2c207f96b8bffabac804eab7888ec88149ab9867db19b7dd",
	 "transactionIndex":"16",
	 "from":"0x687422eea2cb73b5d3e242ba5456b782919afc85",
	 "to":"0x700bc74dd49044446bcb6a25ae5e725d14538825",
	 "value":"1000000000000000000",
	 "gas":"314150",
	 "gasPrice":"5000000000",
	 "isError":"0",
	 "txreceipt_status":"1",
	 "input":"0x",
	 "contractAddress":"",
	 "cumulativeGasUsed":"381927",
	 "gasUsed":"21000",
	 "confirmations":"32316"
 }
 
 */



// MARK: - Web3EthTransaction
struct Web3EthTransaction {
    let transaction: EthereumTransaction
    let transactionBlock: web3swift.Block?
    let lastBlockNumber: BigUInt?
}

extension Web3EthTransaction: TransactionDetailsProtocol {
    var id: String {
        return self.transaction.txhash ?? ""
    }
    
    var senderAddress: String {
        return self.transaction.sender?.address ?? ""
    }
    
    var recipientAddress: String {
        return self.transaction.to.address
    }
    
    var sentDate: Date {
        if let timestamp = self.transactionBlock?.timestamp {
            return timestamp
        } else {
            return Date()
        }
    }
    
    var amountValue: Double {
        guard let string = Web3.Utils.formatToEthereumUnits(self.transaction.value, toUnits: .eth, decimals: 8), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var feeValue: Double {
        guard let string = Web3.Utils.formatToEthereumUnits((self.transaction.gasPrice * self.transaction.gasLimit), toUnits: .eth, decimals: 8), let value = Double(string) else {
            return 0
        }
        
        return value
    }
    
    var confirmationsValue: String {
        if let blockNumber = self.transactionBlock?.number, let lastBlockNumber = self.lastBlockNumber {
            let confirmations = lastBlockNumber - BigUInt(blockNumber)
            return "\(confirmations)"
        } else {
            return "--"
        }
    }
    
    var block: String {
        if let number = self.transactionBlock?.number {
            return "\(number)"
        } else {
            return "--"
        }
    }
    
    var showGoToExplorer: Bool {
        return false
    }
    
    var explorerUrl: URL? {
        return nil
    }
    
    var showGoToChat: Bool {
        return false
    }
    
    var chatroom: Chatroom? {
        return nil
    }
    
    var currencyCode: String {
        return "ETH"
    }
}
