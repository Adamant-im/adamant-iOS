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
	private func getCoreFunction(function key: JSFunctions.CoreFunction) -> JSValue? {
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let function: JSValue?
		if let core = context.objectForKeyedSubscript("adamant_core"),
			let adamant = core.objectForKeyedSubscript("Adamant"),
			let f = adamant.objectForKeyedSubscript(key),
			!f.isUndefined, jsError == nil {
			function = f
		} else {
			function = nil
		}
		
		context.exceptionHandler = nil
		return function
	}
	
	private func getUtilitesFunction(function key: JSFunctions.UtilitesFunction) -> JSValue? {
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let function: JSValue?
		if let f = context.objectForKeyedSubscript(key),
			!f.isUndefined, jsError == nil {
			function = f
		} else {
			function = nil
		}
		
		context.exceptionHandler = nil
		return function
	}
}


// MARK: - Hash converters
extension JSAdamantCore {
	private func convertToJsHash(_ hash: AdamantHash) -> JSValue? {
		guard let converter = getUtilitesFunction(function: .convertToUInt8Array) else {
			return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { context, value in
			jsError = value
		}
		
		let jsHash = converter.call(withArguments: [hash.bytes])
		context.exceptionHandler = nil
		
		if jsError == nil {
			return jsHash
		} else {
			return nil
		}
	}
	
	private func convertFromJsHash(_ jsHash: JSValue) -> AdamantHash? {
		if let bytes = jsHash.toArray() as? [UInt8] {
			return AdamantHash(bytes: bytes)
		} else {
			return nil
		}
	}
}


// MARK: - AdamantCore
extension JSAdamantCore: AdamantCore {
	func createKeypairFor(hash: AdamantHash) -> Keypair? {
		guard hash.bytes.count > 0 else {
			return nil
		}
		
		guard let function = getCoreFunction(function: .makeKeypair) else {
			return nil
		}
		
		if let jsHash = convertToJsHash(hash),
			let keypairRaw = function.call(withArguments: [jsHash]),
			keypairRaw.hasProperty("publicKey") && keypairRaw.hasProperty("privateKey"),
			let publicKey = self.convertFromJsHash(keypairRaw.forProperty("publicKey")),
			let privateKey = self.convertFromJsHash(keypairRaw.forProperty("privateKey")) {
			let keypair = Keypair(publicKey: publicKey, privateKey: privateKey)
			return keypair
		} else {
			return nil
		}
	}
	
	func createKeypairFor(passphrase: String) -> Keypair? {
		guard let hash = createHashFor(passphrase: passphrase), hash.bytes.count > 0 else {
			return nil
		}
		
		return createKeypairFor(hash: hash)
	}
	
	func createHashFor(passphrase: String) -> AdamantHash? {
		guard let function = getCoreFunction(function: .createPassPhraseHash) else {
			return nil
		}
		
		var jsError: JSValue? = nil
		context.exceptionHandler = { ctx, exc in
			jsError = exc
		}
		
		let hash: AdamantHash?
		if let jsHash = function.call(withArguments: [passphrase]),
			!jsHash.isUndefined, jsError == nil {
			hash = convertFromJsHash(jsHash)
		} else {
			hash = nil
		}
		
		context.exceptionHandler = nil
		return hash
	}
}
