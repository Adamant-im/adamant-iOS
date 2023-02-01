//
//  BtcWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 08/02/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import UIKit
import Alamofire
import BitcoinKit

extension BtcWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Bitcoin.transfer) as? BtcTransferViewController else {
            fatalError("Can't get BtcTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<BitcoinKit.Transaction>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = self.btcWallet else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
            completion(.failure(error: .accountNotFound))
            return
        }
        
        let rawAmount = NSDecimalNumber(decimal: amount * BtcWalletService.multiplier).uint64Value
        let fee = NSDecimalNumber(decimal: self.transactionFee * BtcWalletService.multiplier).uint64Value
        
        // MARK: 2. Search for unspent transactions
        getUnspentTransactions { result in
            switch result {
            case .success(let utxos):
                // MARK: 3. Check if we have enought money
                let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
                guard totalAmount >= rawAmount + fee else { // This shit can crash BitcoinKit
                    completion(.failure(error: .notEnoughMoney))
                    break
                }
                
                // MARK: 4. Create local transaction
                let transaction = BitcoinKit.Transaction.createNewTransaction(toAddress: toAddress, amount: rawAmount, fee: fee, changeAddress: changeAddress, utxos: utxos, keys: [key])
                completion(.success(result: transaction))
                
            case .failure:
                completion(.failure(error: .notEnoughMoney))
            }
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        guard let url = AdamantResources.btcServers.randomElement() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.sendTransaction())
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // MARK: Prepare params
        let txHex = transaction.serialized().hex

        // MARK: Sending request
        AF.request(
            endpoint,
            method: .post,
            parameters: nil,
            encoding: BodyStringEncoding(body: txHex),
            headers: headers
        ).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success:
                completion(.success(result: transaction.txId))
            case .failure(let error):
                completion(.failure(error: .remoteServiceError(message: error.localizedDescription)))
            }
        }
    }
    
    func getUnspentTransactions(_ completion: @escaping (ApiServiceResult<[UnspentTransaction]>) -> Void) {
        guard let url = AdamantResources.btcServers.randomElement() else {
            fatalError("Failed to get BTC endpoint URL")
        }
        
        guard let wallet = self.btcWallet else {
            completion(.failure(.notLogged))
            return
        }
        
        let address = wallet.address
        
        // Headers
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(BtcApiCommands.getUnspentTransactions(for: address))
        
        let parameters: Parameters = [
            "noCache": "1"
        ]
        
        // MARK: Sending request
        AF.request(endpoint, method: .get, parameters: parameters, headers: headers).responseData(queue: defaultDispatchQueue) { response in
            switch response.result {
            case .success(let data):
                guard
                    let items = try? Self.jsonDecoder.decode([BtcUnspentTransactionResponse].self,
                                                             from: data)
                else {
                    completion(.failure(.internalError(message: "BTC Wallet: not valid response", error: nil)))
                    break
                }
                
                var utxos = [UnspentTransaction]()
                for item in items {
                    guard item.status.confirmed else {
                        continue
                    }
                        
                    let value = NSDecimalNumber(decimal: item.value).uint64Value
                    
                    let lockScript = wallet.publicKey.toCashaddr().lockingScript
                    let txHash = Data(hex: item.txId).map { Data($0.reversed()) } ?? Data()
                    let txIndex = item.vout
                    
                    let unspentOutput = TransactionOutput(value: value, lockingScript: lockScript)
                    let unspentOutpoint = TransactionOutPoint(hash: txHash, index: txIndex)
                    let utxo = UnspentTransaction(output: unspentOutput, outpoint: unspentOutpoint)
                    
                    utxos.append(utxo)
                }
                
                completion(.success(utxos))
                
            case .failure:
                completion(.failure(.internalError(message: "BTC Wallet: server not response", error: nil)))
            }
        }
    }

}

struct BodyStringEncoding: ParameterEncoding {

    private let body: String

    init(body: String) { self.body = body }

    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        guard var urlRequest = urlRequest.urlRequest else { throw Errors.emptyURLRequest }
        guard let data = body.data(using: .utf8) else { throw Errors.encodingProblem }
        urlRequest.httpBody = data
        return urlRequest
    }
}

extension BodyStringEncoding {
    enum Errors: Error {
        case emptyURLRequest
        case encodingProblem
    }
}

extension BodyStringEncoding.Errors: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .emptyURLRequest: return "Empty url request"
            case .encodingProblem: return "Encoding problem"
        }
    }
}
