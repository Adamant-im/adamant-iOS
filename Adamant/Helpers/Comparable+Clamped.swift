//
//  Comparable+Clamped.swift
//  Adamant
//
//  Created by Anokhov Pavel on 21.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

extension Comparable {
	func clamped(min: Self, max: Self) -> Self {
		if self < min {
			return min
		}
		
		if self > max {
			return max
		}
		
		return self
	}
}
