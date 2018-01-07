//
//  AdamantApi.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 05.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import Foundation

protocol AdamantApi {
	func getAccount(byPassphrase passphrase: String, completionHandler: @escaping (Account?, AdamantError?) -> Void)
	func getAccount(byPublicKey publicKey: AdamantHash, completionHandler: @escaping (Account?, AdamantError?) -> Void)
	
	func getPublicKey(byPassphrase passphrase: String, completionHandler: @escaping (AdamantHash?, AdamantError?) -> Void)
}
