//
//  AdamantCellFactory.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class AdamantCellFactory: CellFactory {
	func nib(for sharedCell: SharedCell) -> UINib? {
		/* UINib.init actually can throw an exception
		do {
			return UINib(nibName: sharedCell.defaultXibName, bundle: nil)
		} catch {
			return nil
		}
		*/

		return UINib(nibName: sharedCell.defaultXibName, bundle: nil)
	}
	
	func cellInstance(for sharedCell: SharedCell) -> UITableViewCell? {
		guard let nib = nib(for: sharedCell) else {
			return nil
		}
		
		let cell = nib.instantiate(withOwner: nil, options: nil).first as? UITableViewCell
		return cell
	}
}
