//
//  CellFactory.swift
//  Adamant-ios
//
//  Created by Pavel Anokhov on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

struct SharedCell: Equatable, Hashable {
	let cellIdentifier: String
	let defaultXibName: String
	let defaultRowHeight: CGFloat
	
	init(cellIdentifier: String, xibName: String, rowHeight: CGFloat) {
		self.cellIdentifier = cellIdentifier
		self.defaultXibName = xibName
		self.defaultRowHeight = rowHeight
	}
	
	static func ==(lhs: SharedCell, rhs: SharedCell) -> Bool {
		return lhs.cellIdentifier == rhs.cellIdentifier &&
			lhs.defaultXibName == rhs.defaultXibName &&
			lhs.defaultRowHeight == rhs.defaultRowHeight
	}
	
	var hashValue: Int {
		return cellIdentifier.hashValue ^ defaultXibName.hashValue ^ defaultRowHeight.hashValue &* 717171
	}
}


protocol CellFactory {
	func nib(for sharedCell: SharedCell) -> UINib?
	func cellInstance(for sharedCell: SharedCell) -> UITableViewCell?
}
