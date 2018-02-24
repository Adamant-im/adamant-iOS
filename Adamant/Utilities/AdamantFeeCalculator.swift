//
//  AdamantFeeCalculator.swift
//  Adamant
//
//  Created by Anokhov Pavel on 16.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class AdamantFeeCalculator {
	static func estimatedFeeFor(message: AdamantMessage) -> UInt64 {
		switch message {
		case .text(let text):
			return AdamantUtilities.from(double: ceil(Double(text.count) / 255.0) * 0.001)
		}
	}
	
	static func estimatedFeeFor(transfer: UInt64) -> UInt64 {
		return AdamantUtilities.from(double: 0.5)
	}
	
	private init() {}
}
