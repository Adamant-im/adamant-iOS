//
//  AdamantDelegateCell.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/07/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import M13Checkbox


// MARK: Cell's Delegate
protocol AdamantDelegateCellDelegate: class {
	func delegateCell(_ cell: AdamantDelegateCell, didChangeCheckedStateTo state: Bool)
}

// MARK: -
class AdamantDelegateCell: UITableViewCell {
	
	// MARK: IBOutlets
	
    @IBOutlet weak var checkbox: M13Checkbox!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var votedLabel: UILabel!

	@IBOutlet weak var checkboxExpander: UIView!
	
	// MARK: Properties
	
	weak var delegate: AdamantDelegateCellDelegate?
	
	var isChecked: Bool {
		set {
			checkbox.checkState = isChecked ? .checked : .unchecked
		}
		get {
			return checkbox.checkState == .checked
		}
	}
	
	func setIsChecked(_ checked: Bool, animated: Bool) {
		checkbox.setCheckState(checked ? .checked : .unchecked, animated: animated)
	}
	
	var delegateIsActive: Bool = false {
		didSet {
			statusLabel.text = delegateIsActive ? "●" : "○"
		}
	}
	
	var isUpvoted: Bool = false {
		didSet {
			votedLabel.text = isUpvoted ? "⬆︎" : ""
		}
	}
	
	var checkmarkColor: UIColor {
		get {
			return checkbox.tintColor
		}
		set {
			checkbox.tintColor = newValue
		}
	}
	
	
	// MARK: Lifecycle
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
		// To avoid too many missclicks, we create a bigger view to catch taps
		checkboxExpander.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onExpanderTap)))
		
		checkbox.addTarget(self, action: #selector(self.onSelectChanged), for: UIControlEvents.valueChanged)
    }

    @objc func onSelectChanged() {
		if let delegate = delegate {
			let state = checkbox.checkState == .checked
			delegate.delegateCell(self, didChangeCheckedStateTo: state)
		}
    }
	
	@objc func onExpanderTap() {
		let state = !isChecked
		setIsChecked(state, animated: true)
		delegate?.delegateCell(self, didChangeCheckedStateTo: state)
	}
}
