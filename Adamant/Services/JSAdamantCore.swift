//
//  JSAdamantCore.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import JavaScriptCore

// MARK: - Functions
private enum JsFunction: String {
	case createPassPhraseHash = "createPassPhraseHash"
	case makeKeypair = "makeKeypair"
	case transactionSign = "transactionSign"
	case encodeMessage = "encodeMessage"
	case decodeMessage = "decodeMessage"
	case generatePassphrase = "generatePassphrase"
	
	var key: String {
		return self.rawValue
	}
}


// MARK: - AdamantCoreError
enum AdamantCoreError: Error {
	case errorLoadingJS(reason: String)
	case errorGettingCoreFunction(function: String)
	case errorCallingFunction(function: String, jsError: String)
}


// MARK: - AdamantCore

/// You must load JavaScript before calling any methods.
class JSAdamantCore : AdamantCore {
	enum Result {
		case success
		case error(error: Error)
	}
	
	private var context: JSContext?
	private var loadingGroup: DispatchGroup?
	
	/// Load JSCore
	func loadJs(from url: URL, queue: DispatchQueue, completionHandler: @escaping (Result) -> Void) {
		let loadingGroup = DispatchGroup()
		self.loadingGroup = loadingGroup
		loadingGroup.enter()
		
		queue.async {
			defer {
				loadingGroup.leave()
				self.loadingGroup = nil
			}
			
			do {
				// MARK: 1. Load JavaScript
				let core = try! String(contentsOf: url)
				
				// MARK: 2. Create context.
				guard let context = JSContext() else {
					throw AdamantCoreError.errorLoadingJS(reason: "Can't create JSContext!")
				}
				
				// MARK: 3. Catch JS errors
				var jsError: JSValue? = nil
				context.exceptionHandler = { context, value in
					print("JSError: \(String(describing: value?.toString()))")
					jsError = value
				}
				
				// MARK: 4. Integrate logger
				context.evaluateScript("var console = { log: function(message) { _consoleLog(message) } }")
				let consoleLog: @convention(block) (String) -> Void = { message in
					print("JSCore: " + message)
				}
				context.setObject(unsafeBitCast(consoleLog, to: AnyObject.self), forKeyedSubscript: "_consoleLog" as (NSCopying & NSObjectProtocol)!)
				
				// MARK: 5. Integrate PRNG, because Webpacks strips out crypto libraries.
				let crypto: @convention(block) (Int) -> JSValue = { count in
					let contextRef = context.jsGlobalContextRef
					let array = JSObjectMakeTypedArray(contextRef, kJSTypedArrayTypeUint8Array, count, nil)!
					let buffer = JSObjectGetTypedArrayBuffer(contextRef, array, nil)!
					let bytes = JSObjectGetArrayBufferBytesPtr(contextRef, buffer, nil)!
					_ = SecRandomCopyBytes(kSecRandomDefault, count, bytes)
					
					
					return JSValue(jsValueRef: array, in: context)
				}
				context.setObject(unsafeBitCast(crypto, to: AnyObject.self), forKeyedSubscript: "_randombytes" as NSCopying & NSObjectProtocol)
				
				// MARK: 6. Evaluate Core script
				context.evaluateScript(core)
				if let jsError = jsError {
					throw AdamantCoreError.errorLoadingJS(reason: jsError.toString())
				}
				
				// MARK: 7. Cleanup
				context.exceptionHandler = nil
				self.context = context
				completionHandler(.success)
			} catch {
				completionHandler(.error(error: error))
			}
		}
	}
}


// MARK: - Working with JS runtime
extension JSAdamantCore {
	private func get(function: JsFunction) -> JSValue? {
		if let group = loadingGroup { // Wait for context loading.
			group.wait()
		}
		
		guard let context = context else {
			print("Context not loaded!")
			return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			print("JSError: \(String(describing: value?.toString()))")
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
	
	private func call(function: JsFunction, with arguments: [Any]) -> JSValue? {
		if let group = loadingGroup { // Wait for context loading.
			group.wait()
		}

		guard let context = context else {
			fatalError("Context not loaded!")
		}

		guard let jsFunction = get(function: function) else {
			fatalError("Failed to get function: \(function.key)")
		}

//		var jsError: JSValue? = nil
		context.exceptionHandler = { ctx, exc in
			print("JSError: \(String(describing: exc?.toString()))")
//			jsError = exc
		}

		let jsValue = jsFunction.call(withArguments: arguments)

		context.exceptionHandler = nil
		return jsValue
	}
}


// MARK: - Hash converters
extension JSAdamantCore {
	private func convertToJsHash(_ hash: [UInt8]) -> JSValue {
		if let group = loadingGroup { // Wait for context loading.
			group.wait()
		}
		
		let count = hash.count
		if count == 0 {
			return JSValue(newArrayIn: context)
		}
		
		let contextRef = context!.jsGlobalContextRef
		let jsArray = JSObjectMakeTypedArray(contextRef, kJSTypedArrayTypeUint8Array, count, nil)!
		let jsBuffer = JSObjectGetTypedArrayBuffer(contextRef, jsArray, nil)!
		let jsBytes = JSObjectGetArrayBufferBytesPtr(contextRef, jsBuffer, nil)!
		
		let typedPointer = jsBytes.bindMemory(to: UInt8.self, capacity: count)
		
		let buffer = UnsafeMutableBufferPointer.init(start: typedPointer, count: count)
		let data = Data(bytes: hash)
		_ = data.copyBytes(to: buffer)
		
		return JSValue(jsValueRef: jsArray, in: context)
	}
	
	private func convertFromJsHash(_ jsHash: JSValue) -> [UInt8]? {
		return jsHash.toArray() as? [UInt8]
	}
}


// MARK: - Keys
extension JSAdamantCore {
	func createKeypairFor(rawHash: [UInt8]) -> Keypair? {
		let jsHash = convertToJsHash(rawHash)
		
		if let keypairRaw = call(function: .makeKeypair, with: [jsHash]),
			keypairRaw.hasProperty("publicKey") && keypairRaw.hasProperty("privateKey"),
			let publicKeyHash = self.convertFromJsHash(keypairRaw.forProperty("publicKey")),
			let privateKeyHash = self.convertFromJsHash(keypairRaw.forProperty("privateKey")) {
			let keypair = Keypair(publicKey: AdamantUtilities.getHexString(from: publicKeyHash),
								  privateKey: AdamantUtilities.getHexString(from: privateKeyHash))
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
		let hash: String?
		
		if let jsHash = call(function: .createPassPhraseHash, with: [passphrase]), !jsHash.isUndefined,
			let hashRaw = convertFromJsHash(jsHash) {
			hash = AdamantUtilities.getHexString(from: hashRaw)
		} else {
			hash = nil
		}
		
		return hash
	}
	
	func generateNewPassphrase() -> String {
		let passphrase: String
		
		if let jsPassphrase = call(function: .generatePassphrase, with: []), !jsPassphrase.isUndefined, let p = jsPassphrase.toString() {
			passphrase = p
		} else {
			fatalError("Can't generate new passphrase")
		}
		
		return passphrase
	}
}



// MARK: - Transactions
extension JSAdamantCore {
	func sign(transaction t: NormalizedTransaction, senderId: String, keypair: Keypair) -> String? {
		let asset: JSAsset
		if let chat = t.asset.chat {
			asset = JSAsset(chat: JSChat(type: chat.type.rawValue, message: chat.message, own_message: chat.ownMessage))
		} else {
			asset = JSAsset(chat: nil)
		}
		
		let jsTransaction = JSTransaction(id: 0,
										  height: 0,
										  blockId: 0,
										  type: t.type.rawValue,
										  timestamp: t.timestamp,
										  senderPublicKey: t.senderPublicKey,
										  senderId: senderId,
										  recipientId: t.recipientId,
										  recipientPublicKey: t.requesterPublicKey,
										  amount: t.amount,
										  fee: 0,
										  signature: "",
										  confirmations: 0,
										  asset: asset)
		
		let jsKeypair = JSKeypair(keypair: keypair)
		
		let signature: String?
		if let jsSignature = call(function: .transactionSign, with: [jsTransaction, jsKeypair]),
			!jsSignature.isUndefined {
			signature = jsSignature.toString()
		} else {
			signature = nil
		}
		
		return signature
	}
}


// MARK: - Messages
extension JSAdamantCore {
	func encodeMessage(_ message: String, recipientPublicKey publicKey: String, privateKey privateKeyHex: String) -> (message: String, nonce: String)? {
		let privateKey = AdamantUtilities.getBytes(from: privateKeyHex)
		
		let encodedMessage: (String, String)?
		if let jsMessage = call(function: .encodeMessage, with: [message, publicKey, privateKey]), !jsMessage.isUndefined,
			let m = jsMessage.forProperty("message").toString(), let o = jsMessage.forProperty("own_message").toString() {
			encodedMessage = (message: m, nonce: o)
		} else {
			encodedMessage = nil
		}
		
		return encodedMessage
	}
	
	func decodeMessage(rawMessage: String, rawNonce: String, senderPublicKey senderKeyHex: String, privateKey privateKeyHex: String) -> String? {
		let message = convertToJsHash(AdamantUtilities.getBytes(from: rawMessage))
		let nonce = convertToJsHash(AdamantUtilities.getBytes(from: rawNonce))
		let senderKey = convertToJsHash(AdamantUtilities.getBytes(from: senderKeyHex))
		let privateKey = convertToJsHash(AdamantUtilities.getBytes(from: privateKeyHex))
		
		let decodedMessage: String?
		if let jsMessage = call(function: .decodeMessage, with: [message, nonce, senderKey, privateKey]),
			!jsMessage.isUndefined, let m = jsMessage.toString() {
			decodedMessage = m
		} else {
			decodedMessage = nil
		}
		
		return decodedMessage
	}
}
