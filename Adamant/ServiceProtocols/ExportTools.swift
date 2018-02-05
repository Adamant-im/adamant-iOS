//
//  ExportTools.swift
//  Adamant
//
//  Created by Anokhov Pavel on 04.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol ExportTools {
	func summaryFor(transaction: Transaction, url: URL) -> String
}
