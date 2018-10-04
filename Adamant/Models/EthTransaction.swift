//
//  EthTransaction.swift
//  Adamant
//
//  Created by Anton Boyarkin on 26/06/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import web3swift
import BigInt

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
    let value: Decimal
    let from: String
    let to: String
    let gasUsed: Decimal
    let gasPrice: Decimal
    let confirmationsValue: String
    let isError: Bool
    let receiptStatus: TransactionReceiptStatus
    let blockNumber: UInt
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
		
        hash = (try? container.decode(String.self, forKey: .hash)) ?? ""
        from = (try? container.decode(String.self, forKey: .from)) ?? ""
        to = (try? container.decode(String.self, forKey: .to)) ?? ""
        confirmationsValue = (try? container.decode(String.self, forKey: .confirmations)) ?? "0"
        receiptStatus = (try? container.decode(TransactionReceiptStatus.self, forKey: .receiptStatus)) ?? .unknown
        blockNumber = UInt((try? container.decode(String.self, forKey: .blockNumber)) ?? "0") ?? 0
        
        if let timeStampRaw = try? container.decode(String.self, forKey: .date), let timeStamp = Double(timeStampRaw) {
            self.date = Date(timeIntervalSince1970: timeStamp)
        } else {
            self.date = Date.init(timeIntervalSince1970: 0)
        }
        
        if let isErrorRaw = try? container.decode(String.self, forKey: .isError) {
            self.isError = isErrorRaw == "1"
        } else {
            self.isError = false
        }
        
        // MARK: Decimals
        if let valueRaw = try? container.decode(String.self, forKey: .value), let value = Decimal(string: valueRaw) {
            self.value = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: value)
        } else {
            self.value = 0
        }
        
        if let gasRaw = try? container.decode(String.self, forKey: .gasUsed), let gas = Decimal(string: gasRaw) {
            self.gasUsed = gas
        } else {
            self.gasUsed = 0
        }
        
        if let gasPriceRaw = try? container.decode(String.self, forKey: .gasPrice), let gasPrice = Decimal(string: gasPriceRaw) {
            self.gasPrice = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: gasPrice)
        } else {
            self.gasPrice = 0
        }
	}
}


// MARK: TransactionDetails
//extension EthTransaction: TransactionDetails {
//    var id: String { return hash }
//    var senderAddress: String { return from }
//    var recipientAddress: String { return to }
//    var sentDate: Date { return date }
//    var confirmations: String { return confirmationsValue }
//    
//    var amount: Decimal {
//        return value.asDecimal(exponent: 8)
//    }
//    
//    var fee: Decimal {
//        return (gasPrice * gasUsed).asDecimal(exponent: 8)
//    }
//    
//    var block: String {
//        return "\(blockNumber)"
//    }
//    
////    var explorerUrl: URL? {
////        return URL(string: "https://etherscan.io/tx/\(id)")
////    }
//    
//    var currencyCode: String {
//        return EthWalletService.currencySymbol
//    }
//}


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
