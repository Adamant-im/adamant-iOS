//
//  JSAdamantCore.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import JavaScriptCore

private struct JSFunctions {
	struct CoreFunction {
		static let createPassPhraseHash = CoreFunction("createPassPhraseHash")
		static let makeKeypair = CoreFunction("makeKeypair")
		static let transactionSign = CoreFunction("transactionSign")
		static let decodeMessage = CoreFunction("decodeMessage")
		
		let key: String
		private init(_ key: String) { self.key = key }
	}
	
	struct UtilitesFunction {
		static let convertToUInt8Array = UtilitesFunction("convertToUInt8Array")
		
		let key: String
		private init(_ key: String) { self.key = key }
	}
	
	private init() {}
}


class JSAdamantCore {
	private let context: JSContext
	
	
	// TODO: background thread
	init(coreJsUrl core: URL, utilitiesJsUrl utils: URL) throws {
		let core = try JSAdamantCore.readStringFrom(url: core)
		let utilities = try JSAdamantCore.readStringFrom(url: utils)
		
		let context = JSContext()
		
		if let context = context {
			var jsError: JSValue? = nil
			context.exceptionHandler = { context, value in
				jsError = value
			}
			
			// TODO: Integrate js logger
			
			// Core
			context.evaluateScript(core)
			if let jsError = jsError {
				context.exceptionHandler = nil
				throw AdamantError(message: "Error evaluating core JS: \(jsError)")
			}
			
			// Utilities
			context.evaluateScript(utilities)
			if let jsError = jsError {
				context.exceptionHandler = nil
				throw AdamantError(message: "Error evaluating core JS: \(jsError)")
			}
			
			context.exceptionHandler = nil
			self.context = context
		} else {
			throw AdamantError(message: "Failed to create JSContext")
		}
	}
	
	private static func readStringFrom(url: URL) throws -> String {
		do {
			return try String(contentsOf: url)
		} catch {
			throw AdamantError(message: "Error reading contents of URL: \(url)", error: error)
		}
	}
}


// MARK: - Working with JS runtime
extension JSAdamantCore {
	private func getCoreFunction(function: JSFunctions.CoreFunction) -> JSValue? {
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let jsFunc: JSValue?
		if let core = context.objectForKeyedSubscript("adamant_core"),
			let adamant = core.objectForKeyedSubscript("Adamant"),
			let f = adamant.objectForKeyedSubscript(function.key),
			!f.isUndefined, jsError == nil {
			jsFunc = f
		} else {
			jsFunc = nil
		}
		
		context.exceptionHandler = nil
		return jsFunc
	}
	
	private func getUtilitesFunction(function: JSFunctions.UtilitesFunction) -> JSValue? {
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let jsFunc: JSValue?
		if let f = context.objectForKeyedSubscript(function.key),
			!f.isUndefined, jsError == nil {
			jsFunc = f
		} else {
			jsFunc = nil
		}
		
		context.exceptionHandler = nil
		return jsFunc
	}
}


// MARK: - Hash converters
extension JSAdamantCore {
	private func convertToJsHash(_ hash: [UInt8]) -> JSValue? {
		guard let converter = getUtilitesFunction(function: .convertToUInt8Array) else {
			return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let jsHash = converter.call(withArguments: [hash])
		context.exceptionHandler = nil
		
		if jsError == nil {
			return jsHash
		} else {
			return nil
		}
	}
	
	private func convertFromJsHash(_ jsHash: JSValue) -> [UInt8]? {
		return jsHash.toArray() as? [UInt8]
	}
}


// MARK: - AdamantCore
extension JSAdamantCore: AdamantCore {
	func createKeypairFor(rawHash: [UInt8]) -> Keypair? {
		guard rawHash.count > 0 else {
			return nil
		}
		
		guard let function = getCoreFunction(function: .makeKeypair) else {
			return nil
		}
		
		if let jsHash = convertToJsHash(rawHash),
			let keypairRaw = function.call(withArguments: [jsHash]),
			keypairRaw.hasProperty("publicKey") && keypairRaw.hasProperty("privateKey"),
			let publicKeyHash = self.convertFromJsHash(keypairRaw.forProperty("publicKey")),
			let privateKeyHash = self.convertFromJsHash(keypairRaw.forProperty("privateKey")) {
			let keypair = Keypair(publicKey: AdamantUtilities.getHexString(from: publicKeyHash), privateKey: AdamantUtilities.getHexString(from: privateKeyHash))
			return keypair
		} else {
			return nil
		}
	}
	
	func createKeypairFor(passphrase: String) -> Keypair? {
		guard let hash = createHashFor(passphrase: passphrase), hash.count > 0 else {
			return nil
		}
		
		return createKeypairFor(rawHash: AdamantUtilities.getBytes(from: hash))
	}
	
	func createHashFor(passphrase: String) -> String? {
		guard let function = getCoreFunction(function: .createPassPhraseHash) else {
			return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { ctx, exc in
			jsError = exc
		}
		
		let hash: String?
		if let jsHash = function.call(withArguments: [passphrase]),
			!jsHash.isUndefined, jsError == nil,
			let hashRaw = convertFromJsHash(jsHash) {
			hash = AdamantUtilities.getHexString(from: hashRaw)
		} else {
			hash = nil
		}
		
		context.exceptionHandler = nil
		return hash
	}
	
	func sign(transaction t: NormalizedTransaction, senderId: String, keypair: Keypair) -> String? {
		guard let function = getCoreFunction(function: .transactionSign), !function.isUndefined else {
			return nil
		}
		
		let jsTransaction = JSTransaction(id: 0, height: 0, blockId: 0, type: t.type.rawValue, timestamp: t.timestamp, senderPublicKey: t.senderPublicKey, senderId: senderId, recipientId: t.recipientId, recipientPublicKey: t.requesterPublicKey, amount: t.amount, fee: 0, signature: "", confirmations: 0)
		let jsKeypair = JSKeypair(keypair: keypair)
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { ctx, exc in
			print(exc!)
			jsError = exc
		}
		
		let signature: String?
		if let jsSignature = function.call(withArguments: [jsTransaction, jsKeypair]),
			!jsSignature.isUndefined, jsError == nil {
			signature = jsSignature.toString()
		} else {
			signature = nil
		}
		
		context.exceptionHandler = nil
		return signature
	}
	
	func decodeMessage(senderKeyHex: String, privateKeyHex: String, rawMessage: String, rawNonce: String) -> String? {
		guard let function = getCoreFunction(function: .decodeMessage), !function.isUndefined else {
			return nil
		}
		
		guard let message = convertToJsHash(AdamantUtilities.getBytes(from: rawMessage)),
			let nonce = convertToJsHash(AdamantUtilities.getBytes(from: rawNonce)),
			let senderKey = convertToJsHash(AdamantUtilities.getBytes(from: senderKeyHex)),
			let privateKey = convertToJsHash(AdamantUtilities.getBytes(from: privateKeyHex))
		else {
				return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { ctx, exc in
			print(exc!)
			jsError = exc
		}
		
		let decodedMessage: String?
		if let jsMessage = function.call(withArguments: [message, nonce, senderKey, privateKey]),
			!jsMessage.isUndefined,
			jsError == nil,
			let m = jsMessage.toString() {
			decodedMessage = m
		} else {
			decodedMessage = nil
		}
		
		context.exceptionHandler = nil
		return decodedMessage
	}
}
