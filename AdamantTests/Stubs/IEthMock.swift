//
//  IEthMock.swift
//  Adamant
//
//  Created by Christian Benua on 15.01.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import Foundation
import BigInt
import web3swift
import Web3Core
@testable import Adamant

final class IEthMock: IEth {
    var provider: Web3Provider {
        _provider
    }
    
    var _provider: Web3Provider! {
        didSet {
            ethDefault._provider = _provider
        }
    }
    
    var ethDefault: EthDefault = EthDefault()
    
    var invokedCallTransaction: Bool = false
    var invokedCallTransactionParameters: CodableTransaction?
    
    func callTransaction(_ transaction: CodableTransaction) async throws -> Data {
        invokedCallTransaction = true
        invokedCallTransactionParameters = transaction
        
        return try await ethDefault.callTransaction(transaction)
    }
    
    func send(_ transaction: CodableTransaction) async throws -> TransactionSendingResult {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var invokedSendRaw: Bool = false
    var invokedSendRawParameters: Data?
    
    func send(raw data: Data) async throws -> TransactionSendingResult {
        invokedSendRaw = true
        invokedSendRawParameters = data
        return try await ethDefault.send(raw: data)
    }
    
    var stubbedEstimateGas: BigUInt = BigUInt(clamping: 22000)

    func estimateGas(for transaction: CodableTransaction, onBlock: BlockNumber) async throws -> BigUInt {
        return stubbedEstimateGas
    }
    
    func feeHistory(blockCount: BigUInt, block: BlockNumber, percentiles: [Double]) async throws -> Oracle.FeeHistory {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func ownedAccounts() async throws -> [EthereumAddress] {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getBalance(for address: EthereumAddress, onBlock: BlockNumber) async throws -> BigUInt {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func block(by hash: Data, fullTransactions: Bool) async throws -> Block {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func block(by number: BlockNumber, fullTransactions: Bool) async throws -> Block {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func block(by hash: Hash, fullTransactions: Bool) async throws -> Block {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func blockNumber() async throws -> BigUInt {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func code(for address: EthereumAddress, onBlock: BlockNumber) async throws -> Hash {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func getLogs(eventFilter: EventFilterParameters) async throws -> [EventLog] {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    var stubbedGasPrice: BigUInt = BigUInt(clamping: 10).toWei()
    
    func gasPrice() async throws -> BigUInt {
        return stubbedGasPrice
    }
    
    func getTransactionCount(for address: EthereumAddress, onBlock: BlockNumber) async throws -> BigUInt {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func transactionDetails(_ txHash: Data) async throws -> Web3Core.TransactionDetails {
        fatalError("\(#file).\(#function) is not implemented")
    }
    
    func transactionReceipt(_ txHash: Data) async throws -> TransactionReceipt {
        fatalError("\(#file).\(#function) is not implemented")
    }
}

final class EthDefault: IEth {
    var provider: Web3Provider {
        _provider
    }
    
    var _provider: Web3Provider!
}
