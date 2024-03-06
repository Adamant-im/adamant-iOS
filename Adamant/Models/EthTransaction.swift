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
import Web3Core
import CommonKit

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

struct EthTransaction {
    let date: Date?
    let hash: String
    let value: Decimal?
    let from: String
    let to: String
    let gasUsed: Decimal?
    let gasPrice: Decimal
    let confirmations: String?
    let isError: Bool
    let receiptStatus: TransactionReceipt.TXStatus
    let blockNumber: String?
    let currencySymbol: String
    
    var nonce: Int? = nil
    var isOutgoing: Bool = false
}

// MARK: Decodable
extension EthTransaction: Decodable {
    enum CodingKeys: String, CodingKey {
        case timeStamp
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
        
        hash = try container.decode(String.self, forKey: .hash)
        from = try container.decode(String.self, forKey: .from)
        to = try container.decode(String.self, forKey: .to)
        blockNumber = try? container.decode(String.self, forKey: .blockNumber)
        confirmations = try? container.decode(String.self, forKey: .confirmations)
        currencySymbol = EthWalletService.currencySymbol
        
        // Status
        if let statusRaw = try? container.decode(String.self, forKey: .receiptStatus) {
            if statusRaw == "1" {
                self.receiptStatus = .ok
            } else {
                self.receiptStatus = .failed
            }
        } else {
            self.receiptStatus = .notYetProcessed
        }
        
        // Date
        if let timeStampRaw = try? container.decode(String.self, forKey: .timeStamp), let timeStamp = Double(timeStampRaw) {
            self.date = Date(timeIntervalSince1970: timeStamp)
        } else {
            self.date = nil
        }
        
        // IsError
        if let isErrorRaw = try? container.decode(String.self, forKey: .isError) {
            self.isError = isErrorRaw == "1"
        } else {
            self.isError = false
        }
        
        // Value/amount
        if let raw = try? container.decode(String.self, forKey: .value), let value = Decimal(string: raw) {
            self.value = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: value)
        } else {
            self.value = 0
        }
        
        // Gas used
        if let raw = try? container.decode(String.self, forKey: .gasUsed), let gas = Decimal(string: raw) {
            self.gasUsed = gas
        } else {
            self.gasUsed = 0
        }
        
        // Gas price
        if let raw = try? container.decode(String.self, forKey: .gasPrice), let gasPrice = Decimal(string: raw) {
            self.gasPrice = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: gasPrice)
        } else {
            self.gasPrice = 0
        }
    }
}

// MARK: - TransactionDetails
extension EthTransaction: TransactionDetails {
    var defaultCurrencySymbol: String? { return currencySymbol }
    
    var txId: String { return hash }
    var senderAddress: String { return from }
    var recipientAddress: String { return to }
    var dateValue: Date? { return date }
    var amountValue: Decimal? { return value }
    var confirmationsValue: String? { return confirmations }
    var blockValue: String? { return blockNumber }
    var feeCurrencySymbol: String? { EthWalletService.currencySymbol }
    
    var feeValue: Decimal? {
        guard let gasUsed = gasUsed else {
            return nil
        }
        
        return gasPrice * gasUsed
    }
    
    var transactionStatus: TransactionStatus? {
        return receiptStatus.asTransactionStatus()
    }
    
    var blockHeight: UInt64? {
        return nil
    }
    
    var nonceRaw: String? {
        guard let nonce = nonce else { return nil }
        
        return String(nonce)
    }
}

// MARK: - From EthereumTransaction
extension CodableTransaction {
    func asEthTransaction(
        date: Date?,
        gasUsed: BigUInt?,
        gasPrice: BigUInt?,
        blockNumber: String?,
        confirmations: String?,
        receiptStatus: TransactionReceipt.TXStatus,
        isOutgoing: Bool,
        hash: String? = nil,
        for token: ERC20Token? = nil
    ) -> EthTransaction {
        
        var recipient = to
        var txValue: BigUInt? = value
        
        var exponent = EthWalletService.currencyExponent
        if let naturalUnits = token?.naturalUnits {
            exponent = -1 * naturalUnits
        }
        
        if data.count > 0 {
            let addressRaw = Data(data[16 ..< 36]).toHexString()
            let erc20RawValue = Data(data[37 ..< 68]).toHexString()
            
            if let address = EthereumAddress("0x\(addressRaw)"), let v = BigUInt(erc20RawValue, radix: 16) {
                recipient = address
                txValue = v
            }
        }

        if receiptStatus == .notYetProcessed {
            txValue = nil
        }
        
        let feePrice: BigUInt
        if type == .eip1559 {
            feePrice = (maxFeePerGas ?? BigUInt(0)) + (maxPriorityFeePerGas ?? BigUInt(0))
        } else {
            feePrice = gasPrice ?? BigUInt(0)
        }
        
        let gasPrice = gasPrice ?? feePrice
        
        return EthTransaction(
            date: date,
            hash: hash ?? txHash ?? "",
            value: txValue?.asDecimal(exponent: exponent),
            from: sender?.address ?? "",
            to: recipient.address,
            gasUsed: gasUsed?.asDecimal(exponent: 0),
            gasPrice: gasPrice.asDecimal(exponent: EthWalletService.currencyExponent),
            confirmations: confirmations,
            isError: receiptStatus != .failed,
            receiptStatus: receiptStatus,
            blockNumber: blockNumber,
            currencySymbol: token?.symbol ?? EthWalletService.currencySymbol,
            nonce: Int(nonce),
            isOutgoing: isOutgoing
        )
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

// MARK: - Adamant ETH API transactions

struct EthTransactionShort {
    let date: Date
    let hash: String
    let from: String
    var to: String
    let gasUsed: Decimal
    let gasPrice: Decimal
    var value: Decimal
    let blockNumber: String
    
    let contract_to: String
    let contract_value: BigUInt
    
    func asEthTransaction(isOutgoing: Bool) -> EthTransaction {
        return EthTransaction(
            date: date,
            hash: hash,
            value: value,
            from: from,
            to: to,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            confirmations: nil,
            isError: false,
            receiptStatus: .ok,
            blockNumber: blockNumber,
            currencySymbol: EthWalletService.currencySymbol,
            isOutgoing: isOutgoing
        )
    }
    
    func asERCTransaction(isOutgoing: Bool, token: ERC20Token) -> EthTransaction {
        let exponent = -1 * token.naturalUnits
        
        return EthTransaction(
            date: date,
            hash: hash,
            value: contract_value.asDecimal(exponent: exponent),
            from: from,
            to: contract_to,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            confirmations: nil,
            isError: false,
            receiptStatus: .ok,
            blockNumber: blockNumber,
            currencySymbol: token.symbol,
            isOutgoing: isOutgoing
        )
    }
}

extension EthTransactionShort: Decodable {
    enum CodingKeys: String, CodingKey {
        case time
        case txfrom
        case txto
        case gas
        case gasprice
        case block
        case txhash
        case value
        case contract_to
        case contract_value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        from = try container.decode(String.self, forKey: .txfrom)
        to = try container.decode(String.self, forKey: .txto)
        
        // Hash
        let hashRaw = try container.decode(String.self, forKey: .txhash)
        hash = hashRaw.replacingOccurrences(of: "\\", with: "0")
        
        // Block
        let blockRaw = try container.decode(UInt64.self, forKey: .block)
        blockNumber = String(blockRaw)
        
        // Date
        let timestamp = try container.decode(TimeInterval.self, forKey: .time)
        date = Date(timeIntervalSince1970: timestamp)
        
        // Gas used
        gasUsed = try container.decode(Decimal.self, forKey: .gas)
        
        // Gas price
        let gasPriceRaw = try container.decode(Decimal.self, forKey: .gasprice)
        gasPrice = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: gasPriceRaw)
        
        // Value
        let valueRaw = try container.decode(Decimal.self, forKey: .value)
        value = Decimal(sign: .plus, exponent: EthWalletService.currencyExponent, significand: valueRaw)
        
        contract_to = try container.decodeIfPresent(String.self, forKey: .contract_to) ?? ""
        
        let contractValueRaw = try container.decodeIfPresent(String.self, forKey: .contract_value) ?? "0"
        contract_value = BigUInt(contractValueRaw, radix: 16) ?? BigUInt.zero
        
        if !contract_to.isEmpty {
            let address = "0x" + contract_to.reversed()[..<40].reversed()
            to = address
        }
    }
}

// MARK: Adamant node Sample JSON
/*
 
 {
     "time": 1540676411,
     "txfrom": "0xcE25C5bbEB9f27ac942f914183279FDB31C999dC",
     "txto": "0x201B95b75B4114A825b278710307EFA0b5A5Ebf1",
     "gas": 21000,
     "gasprice": 4000000000,
     "block": 6595442,
     "txhash": "\\x998b47613f294dd6795ccd28e2c68f244a97a87e20ba30f88012a34e899d029b",
     "value": 4000000000000000000,
     "contract_to": "",
     "contract_value": ""
 }
 
 Note broken txhash
 contract_to & contract_value not requested from API
 
 */
