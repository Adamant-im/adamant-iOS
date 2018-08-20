//
//  UIView+constraints.swift
//  Adamant
//
//  Created by Anokhov Pavel on 10.08.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

extension UIView {
	func constrainCentered(_ subview: UIView) {
		subview.translatesAutoresizingMaskIntoConstraints = false
		
		let verticalContraint = NSLayoutConstraint(
			item: subview,
			attribute: .centerY,
			relatedBy: .equal,
			toItem: self,
			attribute: .centerY,
			multiplier: 1.0,
			constant: 0)
		
		let horizontalContraint = NSLayoutConstraint(
			item: subview,
			attribute: .centerX,
			relatedBy: .equal,
			toItem: self,
			attribute: .centerX,
			multiplier: 1.0,
			constant: 0)
		
		let heightContraint = NSLayoutConstraint(
			item: subview,
			attribute: .height,
			relatedBy: .equal,
			toItem: nil,
			attribute: .notAnAttribute,
			multiplier: 1.0,
			constant: subview.frame.height)
		
		let widthContraint = NSLayoutConstraint(
			item: subview,
			attribute: .width,
			relatedBy: .equal,
			toItem: nil,
			attribute: .notAnAttribute,
			multiplier: 1.0,
			constant: subview.frame.width)
		
		addConstraints([
			horizontalContraint,
			verticalContraint,
			heightContraint,
			widthContraint])
	}
	
	func constrainToEdges(_ subview: UIView, relativeToSafeArea: Bool = false) {
		subview.translatesAutoresizingMaskIntoConstraints = false
		
		let topContraint: NSLayoutConstraint
		let bottomConstraint: NSLayoutConstraint
		
		if relativeToSafeArea, #available(iOS 11, *) {
			topContraint = subview.topAnchor.constraintEqualToSystemSpacingBelow(safeAreaLayoutGuide.topAnchor, multiplier: 1.0)
			bottomConstraint = safeAreaLayoutGuide.bottomAnchor.constraintEqualToSystemSpacingBelow(subview.bottomAnchor, multiplier: 1.0)
		} else {
			topContraint = NSLayoutConstraint(
				item: subview,
				attribute: .top,
				relatedBy: .equal,
				toItem: self,
				attribute: .top,
				multiplier: 1.0,
				constant: 0)
			
			bottomConstraint = NSLayoutConstraint(
				item: subview,
				attribute: .bottom,
				relatedBy: .equal,
				toItem: self,
				attribute: .bottom,
				multiplier: 1.0,
				constant: 0)
		}
		
		let leadingContraint = NSLayoutConstraint(
			item: subview,
			attribute: .leading,
			relatedBy: .equal,
			toItem: self,
			attribute: .leading,
			multiplier: 1.0,
			constant: 0)
		
		let trailingContraint = NSLayoutConstraint(
			item: subview,
			attribute: .trailing,
			relatedBy: .equal,
			toItem: self,
			attribute: .trailing,
			multiplier: 1.0,
			constant: 0)
		
		addConstraints([
			topContraint,
			bottomConstraint,
			leadingContraint,
			trailingContraint])
	}
}
