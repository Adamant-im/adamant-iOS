//
//  TextViewTableViewCell.swift
//  Adamant
//
//  Created by Anokhov Pavel on 23.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import TableKit
import GrowingTextView

extension SharedCell {
	static let TextViewCell = SharedCell(cellIdentifier: "textCell",
									   xibName: "TextViewTableViewCell",
									   rowHeight: 44)
}

protocol TextViewTableViewCellDelegate: class {
	func cellDidChangeHeight(_ textView: TextViewTableViewCell, height: CGFloat)
}

class TextViewTableViewCell: UITableViewCell {
	@IBOutlet weak var textView: UITextView!
	weak var delegate: TextViewTableViewCellDelegate?
	
	var placeHolder: String? {
		set {
			if let tv = textView as? GrowingTextView {
				tv.placeHolder = placeHolder
			}
		}
		get {
			return (textView as? GrowingTextView)?.placeHolder
		}
	}
	
	override func awakeFromNib() {
		(textView as? GrowingTextView)?.delegate = self
	}
}

extension TextViewTableViewCell: GrowingTextViewDelegate {
	func textViewDidChangeHeight(_ textView: GrowingTextView, height: CGFloat) {
		delegate?.cellDidChangeHeight(self, height: height)
	}
}

extension TextViewTableViewCell: ConfigurableCell {
	func configure(with string: String) {
		textView.text = string
	}
}
