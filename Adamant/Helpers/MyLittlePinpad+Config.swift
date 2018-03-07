//
//  MyLittlePinpad+Config.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MyLittlePinpad

extension String.adamantLocalized {
	struct pinpad {
		static let createPin = NSLocalizedString("Enter new pin", comment: "Pinpad: Ask user to create new pin")
		static let repeatPin = NSLocalizedString("Re-enter new pin", comment: "Pinpad: Ask user to repeat new pin")
	}
}

extension PinpadViewController {
	static func adamantPinpad(biometryButton: PinpadBiometryButtonType) -> PinpadViewController {
		let pinpad = PinpadViewController.instantiateFromNib()
		
		pinpad.bordersColor = UIColor.adamantSecondary
		pinpad.setColor(UIColor.adamantPrimary, for: .normal)
		pinpad.buttonsHighlightedColor = UIColor.adamantPinpadHighlightButton
		pinpad.buttonsSize = 75
		pinpad.buttonsSpacing = 20
		pinpad.placeholderViewHeight = 50
		pinpad.placeholdersSize = 15
		pinpad.placeholderActiveColor = UIColor.adamantPinpadHighlightButton
		pinpad.biometryButtonType = biometryButton
		
		return pinpad
	}
}
