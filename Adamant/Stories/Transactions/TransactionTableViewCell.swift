//
//  TransactionTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 08.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
	enum TransactionType {
		case income, outcome
		
		var imageTop: UIImage {
			switch self {
			case .income: return #imageLiteral(resourceName: "transfer-in_top")
			case .outcome: return #imageLiteral(resourceName: "transfer-out_top")
			}
		}
		
		var imageBottom: UIImage {
			switch self {
			case .income: return #imageLiteral(resourceName: "transfer-in_bot")
			case .outcome: return #imageLiteral(resourceName: "transfer-out_bot")
			}
		}
		
		var bottomTintColor: UIColor {
			switch self {
			case .income: return UIColor.adamantTransferIncomeIconBackground
			case .outcome: return UIColor.adamantTransferOutcomeIconBackground
			}
		}
	}
	
	// MARK: - IBOutlets
	
	@IBOutlet weak var topImageView: UIImageView!
	@IBOutlet weak var bottomImageView: UIImageView!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var ammountLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
	
	// MARK: - Properties
	
	var transactionType: TransactionType = .income {
		didSet {
			topImageView.image = transactionType.imageTop
			bottomImageView.image = transactionType.imageBottom
			bottomImageView.tintColor = transactionType.bottomTintColor
		}
	}
	
	
	// MARK: - Initializers
	
	override func awakeFromNib() {
		transactionType = .income
	}
}
