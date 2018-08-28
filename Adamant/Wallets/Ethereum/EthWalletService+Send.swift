//
//  EthWalletService+Send.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import web3swift
import BigInt

extension EthWalletService: WalletServiceWithSendExtended {
	
	typealias T = String
	
	func transferViewController() -> UIViewController {
		guard let vc = router.get(scene: AdamantScene.Wallets.Ethereum.transfer) as? EthTransferViewController else {
			fatalError("Can't get EthTransferViewController")
		}
		
		vc.service = self
		return vc
	}
	
	func sendMoney(recipient: String, amount: Decimal, completion: @escaping (WalletServiceSimpleResult) -> Void) {
		sendFunds(toEthRecipient: recipient, amount: amount) { result in
			switch result {
			case .success:
				completion(.success)
				
			case .failure(let error):
				completion(.failure(error: error))
			}
		}
	}
	
	func sendMoney(recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<String>) -> Void) {
		sendFunds(toEthRecipient: recipient, amount: amount) { result in
			switch result {
			case .success(let hash):
				completion(.success(result: hash))
				
			case .failure(let error):
				completion(.failure(error: error))
			}
		}
	}
	
	
	// MARK: - Tools
	
	/// Create intermediate transaction
	private func sendFunds(toEthRecipient recipient: String, amount: Decimal, completion: @escaping (WalletServiceResult<String>) -> Void) {
		// MARK: 1. Prepare
		
		guard let ethWallet = ethWallet else {
			completion(.failure(error: .notLogged))
			return
		}
		
		guard let ethRecipient = EthereumAddress(recipient) else {
			completion(.failure(error: .accountNotFound))
			return
		}
		
		guard let bigUIntAmount = Web3.Utils.parseToBigUInt("\(amount)", units: .eth) else {
			completion(.failure(error: .invalidAmount(amount)))
			return
		}
		
		// MARK: Go background
		defaultDispatchQueue.async {
			// MARK: 2. Create contract
			
			var options = Web3Options.defaultOptions()
			options.from = ethWallet.ethAddress
			options.value = bigUIntAmount
			
			guard let contract = self.web3.contract(Web3.Utils.coldWalletABI, at: ethRecipient) else {
				completion(.failure(error: .internalError(message: "ETH Wallet: Send - contract loading error", error: nil)))
				return
			}
			
			guard let estimatedGas = contract.method(options: options)?.estimateGas(options: nil).value else {
				completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving estimated gas error", error: nil)))
				return
			}
			
			options.gasLimit = estimatedGas
			
			guard let gasPrice = self.web3.eth.getGasPrice().value else {
				completion(.failure(error: .internalError(message: "ETH Wallet: Send - retrieving gas price error", error: nil)))
				return
			}
			
			options.gasPrice = gasPrice
			
			guard let intermediate = contract.method(options: options) else {
				completion(.failure(error: .internalError(message: "ETH Wallet: Send - create transaction issue", error: nil)))
				return
			}
			
			
			// MARK: 3. Send
			
			let result = intermediate.send(password: "", options: nil)
			
			switch result {
			case .success(let result):
				if let hash = result["txhash"] {
					completion(.success(result: hash))
				} else {
					completion(.failure(error: .internalError(message: "Failed to get transaction hash", error: nil)))
				}
				
			case .failure(let error):
				completion(.failure(error: error.asWalletServiceError()))
			}
		}
	}
}
