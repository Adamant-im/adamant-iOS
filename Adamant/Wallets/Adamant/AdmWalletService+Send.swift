//
//  AdmWalletService+Send.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension AdmWalletService: WalletServiceWithSend {
	/// Transaction ID
	typealias T = Int
	
	func transferViewController() -> UIViewController {
		guard let vc = router.get(scene: AdamantScene.Wallets.Adamant.transfer) as? AdmTransferViewController else {
			fatalError("Can't get AdmTransferViewController")
		}
		
		vc.service = self
		return vc
	}
	
	
	/// Comments not implemented
	func sendMoney(recipient: String, amount: Decimal, comments: String, completion: @escaping (WalletServiceResult<String?>) -> Void) {
		guard let apiService = apiService else { // Hold reference
			fatalError("AdmWalletService: Dependency failed: ApiService")
		}
		
		guard let account = accountService.account, let keypair = accountService.keypair else {
			completion(.failure(error: .notLogged))
			return
		}
		
		apiService.getPublicKey(byAddress: recipient) { result in
			switch result {
			case .success:
				apiService.transferFunds(sender: account.address, recipient: recipient, amount: amount, keypair: keypair) { result in
					switch result {
					case .success:
						completion(.success(result: nil))
						
					case .failure(let error):
						completion(.failure(error: error.asWalletServiceError()))
					}
				}
				
			case .failure(let error):
				completion(.failure(error: error.asWalletServiceError()))
			}
		}
	}
}
