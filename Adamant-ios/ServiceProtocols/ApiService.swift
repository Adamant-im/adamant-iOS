//
//  ApiService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol ApiService {
	func getAccount(byPassphrase passphrase: String, completionHandler: @escaping (Account?, AdamantError?) -> Void)
	func getAccount(byPublicKey publicKey: AdamantHash, completionHandler: @escaping (Account?, AdamantError?) -> Void)
	
	func getPublicKey(byPassphrase passphrase: String, completionHandler: @escaping (AdamantHash?, AdamantError?) -> Void)
	
	func getTransactions(forAccount: String, type: TransactionType, completionHandler: @escaping ([Transaction]?, AdamantError?) -> Void)
}
