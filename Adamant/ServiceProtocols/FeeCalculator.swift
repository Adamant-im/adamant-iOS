//
//  FeeCalculator.swift
//  Adamant
//
//  Created by Anokhov Pavel on 16.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

protocol FeeCalculator {
	func estimatedFeeFor(message: AdamantMessage) -> UInt
	func estimatedFeeFor(transfer: UInt) -> UInt
}
