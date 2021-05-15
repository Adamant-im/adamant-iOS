//
//  Transaction.swift
//
//  Copyright © 2018 Kishikawa Katsumi
//  Copyright © 2018 BitcoinKit developers
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// tx describes a bitcoin transaction, in reply to getdata
public struct Transaction {
    /// Transaction data format version (note, this is signed)
    public let version: UInt32
    /// If present, always 0001, and indicates the presence of witness data
    // public let flag: UInt16 // If present, always 0001, and indicates the presence of witness data
    /// Number of Transaction inputs (never zero)
    public var txInCount: VarInt {
        return VarInt(inputs.count)
    }
    /// A list of 1 or more transaction inputs or sources for coins
    public var inputs: [TransactionInput]
    /// Number of Transaction outputs
    public var txOutCount: VarInt {
        return VarInt(outputs.count)
    }
    /// A list of 1 or more transaction outputs or destinations for coins
    public var outputs: [TransactionOutput]
    /// A list of witnesses, one for each input; omitted if flag is omitted above
    // public let witnesses: [TransactionWitness] // A list of witnesses, one for each input; omitted if flag is omitted above
    /// The block number or timestamp at which this transaction is unlocked:
    public let lockTime: UInt32

    public var txHash: Data {
        return Crypto.sha256sha256(serialized())
    }

    public var txID: String {
        return Data(txHash.reversed()).hex
    }

    public init(version: UInt32, inputs: [TransactionInput], outputs: [TransactionOutput], lockTime: UInt32) {
        self.version = version
        self.inputs = inputs
        self.outputs = outputs
        self.lockTime = lockTime
    }

    public func serialized() -> Data {
        var data = Data()
        data += version
        data += txInCount.serialized()
        data += inputs.flatMap { $0.serialized() }
        data += txOutCount.serialized()
        data += outputs.flatMap { $0.serialized() }
        data += lockTime
        return data
    }
    
    public mutating func unpack(with network: Network) {
        for index in 0..<inputs.count {
            inputs[index].unpack(with: network)
        }
        
        for index in 0..<outputs.count {
            outputs[index].unpack(with: network)
        }
    }
    
    public func isLinked(to address: Cashaddr) -> Bool {
        let hash = address.base58
        return inputs.filter { input -> Bool in input.address == hash }.count > 0
            || outputs.filter { output -> Bool in output.address == hash }.count > 0
    }

    public func isCoinbase() -> Bool {
        return inputs.count == 1 && inputs[0].isCoinbase()
    }

    public static func deserialize(_ data: Data) -> Transaction {
        let byteStream = ByteStream(data)
        return deserialize(byteStream)
    }

    static func deserialize(_ byteStream: ByteStream) -> Transaction {
        let version = byteStream.read(UInt32.self)
        let txInCount = byteStream.read(VarInt.self)
        var inputs = [TransactionInput]()
        for _ in 0..<Int(txInCount.underlyingValue) {
            inputs.append(TransactionInput.deserialize(byteStream))
        }
        let txOutCount = byteStream.read(VarInt.self)
        var outputs = [TransactionOutput]()
        for _ in 0..<Int(txOutCount.underlyingValue) {
            outputs.append(TransactionOutput.deserialize(byteStream))
        }
        let lockTime = byteStream.read(UInt32.self)
        return Transaction(version: version, inputs: inputs, outputs: outputs, lockTime: lockTime)
    }
    
    static public func createNewTransaction(toAddress: Address, amount: UInt64, fee: UInt64, changeAddress: Address, utxos: [UnspentTransaction], lockTime: UInt32 = 0, keys:  [PrivateKey]) -> Transaction {
        let unsignedTx = createUnsignedTx(toAddress: toAddress, amount: amount, fee: fee, changeAddress: changeAddress, utxos: utxos, lockTime: 0)
        let signedTransaction = signTx(unsignedTx: unsignedTx, keys: keys)
        
        return signedTransaction
    }
    
    static private func selectTx(from utxos: [UnspentTransaction], amount: UInt64, fee: UInt64) -> [UnspentTransaction] {
        
        var selected = [UnspentTransaction]()
        
        let target = amount + fee
        var transferAmount: UInt64 = 0
        utxos.forEach { transaction in
            let amount = transaction.output.value
            if (transferAmount < target) {
                transferAmount += amount
                
                selected.append(transaction)
            }
        }
        
        return selected
    }
    
    static private func createUnsignedTx(toAddress: Address, amount: UInt64, fee: UInt64, changeAddress: Address, utxos: [UnspentTransaction], lockTime: UInt32 = 0) -> UnsignedTransaction {
        let utxos = selectTx(from: utxos, amount: amount, fee: fee)
        let totalAmount: UInt64 = UInt64(utxos.reduce(0) { $0 + $1.output.value })
        let change: UInt64 = totalAmount - amount - fee
        
        let toPubKeyHash: Data = toAddress.data
        let changePubkeyHash: Data = changeAddress.data
        
        let lockingScriptTo = Script.buildPublicKeyHashOut(pubKeyHash: toPubKeyHash)
        let lockingScriptChange = Script.buildPublicKeyHashOut(pubKeyHash: changePubkeyHash)
        
        var outputs = [TransactionOutput]()
        outputs.append(TransactionOutput(value: amount, lockingScript: lockingScriptTo))
        if change > 0 {
            outputs.append(TransactionOutput(value: change, lockingScript: lockingScriptChange))
        }
        
        let unsignedInputs = utxos.map { TransactionInput(previousOutput: $0.outpoint, signatureScript: Data(), sequence: UInt32.max) }
        let tx = BitcoinKit.Transaction(version: 1, inputs: unsignedInputs, outputs: outputs, lockTime: lockTime)
        return UnsignedTransaction(tx: tx, utxos: utxos)
    }
    
    static private func signTx(unsignedTx: UnsignedTransaction, keys: [PrivateKey]) -> Transaction {
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
