//
//  TransactionTableViewCell.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension SharedCell {
	static let TransactionCell = SharedCell(cellIdentifier: "transactionCell",
											xibName: "TransactionTableViewCell",
											rowHeight: 90)
}

class TransactionTableViewCell: UITableViewCell {
	
	enum TransactionType {
		case income, outcome
		
		var image: UIImage {
			switch self {
			case .income:
				return #imageLiteral(resourceName: "income")
				
			case .outcome:
				return #imageLiteral(resourceName: "outcome")
			}
		}
	}
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var avatarImageView: UIImageView!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var ammountLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	
	// MARK: - Properties
	
	var transactionType: TransactionType = .income {
		didSet {
			avatarImageView.image = transactionType.image
		}
	}
	
	// MARK: - Initializers
	override func awakeFromNib() {
		transactionType = .income
		avatarImageView?.image = transactionType.image
	}
}
