//
//  EurekaAlertLabelRow.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.07.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Eureka
import FreakingSimpleRoundImageView

public final class AlertLabelCell: Cell<String>, CellType {
	var inCellAccessoryView: UIView!
	private (set) var alertLabel: RoundedLabel!
	
	required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		if style == .value1, let detailTextLabel = detailTextLabel {
			let label = RoundedLabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			contentView.addSubview(label)
			contentView.addConstraints(AlertLabelCell.alertConstraints(for: label, relativeTo: detailTextLabel))
			
			alertLabel = label
		}
		
		alertLabel = nil
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		if let detailTextLabel = detailTextLabel {
			let label = RoundedLabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			contentView.addSubview(label)
			contentView.addConstraints(AlertLabelCell.alertConstraints(for: label, relativeTo: detailTextLabel))
			
			alertLabel = label
		}
	}
	
	private static func alertConstraints(for item: UIView, relativeTo toItem: UIView) -> [NSLayoutConstraint] {
		return [NSLayoutConstraint(item: item, attribute: .trailing, relatedBy: .equal, toItem: toItem, attribute: .leading, multiplier: 1, constant: -8),
				NSLayoutConstraint(item: item, attribute: .centerY, relatedBy: .equal, toItem: toItem, attribute: .centerY, multiplier: 1, constant: 0)]
	}
}

public final class AlertLabelRow: Row<AlertLabelCell>, RowType {
	required public init(tag: String?) {
		super.init(tag: tag)
		cellProvider = CellProvider<AlertLabelCell>(nibName: "AlertLabelCell")
	}
}
