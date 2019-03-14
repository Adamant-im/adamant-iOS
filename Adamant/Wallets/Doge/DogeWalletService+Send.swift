//
//  DogeWalletService+Send.swift
//  Adamant
//
//  Created by Anton Boyarkin on 12/03/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import BitcoinKit
import BitcoinKit.Private
import Alamofire

extension BitcoinKit.Transaction: RawTransaction {
    var txHash: String? {
        return txID
    }
}

extension DogeWalletService: WalletServiceTwoStepSend {
    typealias T = BitcoinKit.Transaction
    
    func transferViewController() -> UIViewController {
        guard let vc = router.get(scene: AdamantScene.Wallets.Doge.transfer) as? DogeTransferViewController else {
            fatalError("Can't get DogeTransferViewController")
        }
        
        vc.service = self
        return vc
    }
    
    
    // MARK: Create & Send
    func createTransaction(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<BitcoinKit.Transaction>) -> Void) {
        // MARK: 1. Prepare
        guard let wallet = self.dogeWallet else {
            completion(.failure(error: .notLogged))
            return
        }
        
        let changeAddress = wallet.publicKey.toCashaddr()
        let key = wallet.privateKey
        
        guard let toAddress = try? LegacyAddress(recipient, for: self.network) else {
            completion(.failure(error: .accountNotFound))
            return
        }
        
        let rawAwount = NSDecimalNumber(decimal: amount * Decimal(DogeWalletService.multiplier)).int64Value
        
        // MARK: Go background
        defaultDispatchQueue.async {
            // MARK: 2. Search for unspent transactions
            self.getUnspentTransactions({ result in
                switch result {
                case .success(let utxos):
                    // MARK: 3. Create local transaction
                    let unsignedTx = self.createUnsignedTx(toAddress: toAddress, amount: rawAwount, changeAddress: changeAddress, utxos: utxos, lockTime: 0)
                    let signedTransaction = self.signTx(unsignedTx: unsignedTx, keys: [key])
                    completion(.success(result: signedTransaction))
                    break
                case .failure(let error):
                    completion(.failure(error: .notEnoughMoney))
                    break
                }
            })
        }
    }
    
    func sendTransaction(_ transaction: BitcoinKit.Transaction, completion: @escaping (WalletServiceResult<String>) -> Void) {
        guard let raw = AdamantResources.dogeServers.randomElement(), let url = URL(string: raw) else {
            fatalError("Failed to build DOGE endpoint URL")
        }
        
        // Headers
        let headers = [
            "Content-Type": "application/json"
        ]
        
        // Request url
        let endpoint = url.appendingPathComponent(DogeApiCommands.sendTransaction())
        
        defaultDispatchQueue.async {
            // MARK: Prepare params
            let txHex = transaction.serialized().hex
            
            let parameters: [String : Any] = [
                "rawtx": txHex
            ]
            
            // MARK: Sending request
            Alamofire.request(endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: self.defaultDispatchQueue) { response in
                
                switch response.result {
                case .success(let data):
                    
                    if let result = data as? [String: Any], let txid = result["txid"] as? String {
                        completion(.success(result: txid))
                    } else {
                        completion(.failure(error: .internalError(message: "DOGE Wallet: not valid response", error: nil)))
                    }
                    
                case .failure:
                    completion(.failure(error: .internalError(message: "DOGE Wallet: server not response", error: nil)))
                }
            }
        }
    }
    
    // TODO: select utxos and decide fee
    public func selectTx(from utxos: [UnspentTransaction], amount: Int64) -> (utxos: [UnspentTransaction], fee: Int64) {
        return (utxos, NSDecimalNumber(decimal: self.transactionFee * Decimal(DogeWalletService.multiplier)).int64Value)
    }
    
    public func createUnsignedTx(toAddress: Address, amount: Int64, changeAddress: Address, utxos: [UnspentTransaction], lockTime: UInt32 = 0) -> UnsignedTransaction {
        let (utxos, fee) = selectTx(from: utxos, amount: amount)
        let totalAmount: Int64 = Int64(utxos.reduce(0) { $0 + $1.output.value })
        let change: Int64 = totalAmount - amount - fee
        
        let toPubKeyHash: Data = toAddress.data
        let changePubkeyHash: Data = changeAddress.data
        
        let lockingScriptTo = Script.buildPublicKeyHashOut(pubKeyHash: toPubKeyHash)
        let lockingScriptChange = Script.buildPublicKeyHashOut(pubKeyHash: changePubkeyHash)
        
        let toOutput = TransactionOutput(value: UInt64(amount), lockingScript: lockingScriptTo)
        let changeOutput = TransactionOutput(value: UInt64(change), lockingScript: lockingScriptChange)
        
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: UInt32.max) }
        let tx = BitcoinKit.Transaction(version: 1, inputs: unsignedInputs, outputs: [toOutput, changeOutput], lockTime: lockTime)
        return UnsignedTransaction(tx: tx, utxos: utxos)
    }
    
    public func signTx(unsignedTx: UnsignedTransaction, keys: [PrivateKey]) -> BitcoinKit.Transaction {
        var inputsToSign = unsignedTx.tx.inputs
        var transactionToSign: BitcoinKit.Transaction {
            return BitcoinKit.Transaction(version: unsignedTx.tx.version, inputs: inputsToSign, outputs: unsignedTx.tx.outputs, lockTime: unsignedTx.tx.lockTime)
        }
        
        // Signing
        let hashType = SighashType.BTC.ALL
        for (i, utxo) in unsignedTx.utxos.enumerated() {
            let pubkeyHash: Data = Script.getPublicKeyHash(from: utxo.output.lockingScript)
            
            let keysOfUtxo: [PrivateKey] = keys.filter { $0.publicKey().pubkeyHash == pubkeyHash }
            guard let key = keysOfUtxo.first else {
                print("No keys to this txout : \(utxo.output.value)")
                continue
            }
            print("Value of signing txout : \(utxo.output.value)")
            
            let sighash: Data = transactionToSign.signatureHash(for: utxo.output, inputIndex: i, hashType: SighashType.BTC.ALL)
            let signature: Data = try! BitcoinKit.Crypto.sign(sighash, privateKey: key)
            let txin = inputsToSign[i]
            let pubkey = key.publicKey()
            
            let unlockingScript = Script.buildPublicKeyUnlockingScript(signature: signature, pubkey: pubkey, hashType: hashType)
            
            inputsToSign[i] = TransactionInput(previousOutput: txin.previousOutput, signatureScript: unlockingScript, sequence: txin.sequence)
        }
        return transactionToSign
    }
}

extension BitcoinKit.Transaction: TransactionDetails {
    var txId: String {
        return txID
    }
    
    var dateValue: Date? {
        switch lockTime {
        case 1..<500000000:
            return nil
        case 500000000...:
            return Date(timeIntervalSince1970: TimeInterval(lockTime))
        default:
            return nil
        }
    }
    
    var amountValue: Decimal {
        return Decimal(outputs[0].value) / Decimal(100000000)
    }
    
    var feeValue: Decimal? {
        return nil
    }
    
    var confirmationsValue: String? {
        return "0"
    }
    
    var blockValue: String? {
        return nil
    }
    
    var isOutgoing: Bool {
        return true
    }
    
    var transactionStatus: TransactionStatus? {
        return .pending
    }
    
    var senderAddress: String {
        return ""
    }
    
    var recipientAddress: String {
        return ""
    }
}

public protocol BinaryConvertible {
    static func +(lhs: Data, rhs: Self) -> Data
    static func +=(lhs: inout Data, rhs: Self)
}

public extension BinaryConvertible {
    public static func +(lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        return lhs + data
    }
    
    public static func +=(lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
}

extension UInt8 : BinaryConvertible {}
extension UInt16 : BinaryConvertible {}
extension UInt32 : BinaryConvertible {}
extension UInt64 : BinaryConvertible {}
extension Int8 : BinaryConvertible {}
extension Int16 : BinaryConvertible {}
extension Int32 : BinaryConvertible {}
extension Int64 : BinaryConvertible {}
extension Int : BinaryConvertible {}

extension Bool : BinaryConvertible {
    public static func +(lhs: Data, rhs: Bool) -> Data {
        return lhs + (rhs ? UInt8(0x01) : UInt8(0x00)).littleEndian
    }
}

extension String : BinaryConvertible {
    public static func +(lhs: Data, rhs: String) -> Data {
        guard let data = rhs.data(using: .ascii) else { return lhs}
        return lhs + data
    }
}

extension Data : BinaryConvertible {
    public static func +(lhs: Data, rhs: Data) -> Data {
        var data = Data()
        data.append(lhs)
        data.append(rhs)
        return data
    }
}

enum SignError: Error {
    case noPreviousOutput
    case noPreviousOutputAddress
    case noPrivateKey
}

enum SerializationError: Error {
    case noPreviousOutput
    case noPreviousTransaction
}
