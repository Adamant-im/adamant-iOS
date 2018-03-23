//
//  MyLittlePinpad+adamant.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.03.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import MyLittlePinpad

extension String.adamantLocalized {
	struct pinpad {
		static let createPin = NSLocalizedString("Pinpad.EnterNewPin", comment: "Pinpad: Ask user to create new pin")
		static let reenterPin = NSLocalizedString("Pinpad.ReenterPin", comment: "Pinpad: Ask user to repeat new pin")
	}
}

extension PinpadBiometryButtonType {
	var localAuthType: BiometryType {
		switch self {
		case .hidden:
			return .none
			
		case .faceID:
			return .faceID
			
		case .touchID:
			return .touchID
		}
	}
}

extension BiometryType {
	var pinpadButtonType: PinpadBiometryButtonType {
		switch self {
		case .none:
			return .hidden
		
		case .faceID:
			return .faceID
			
		case .touchID:
			return .touchID
		}
	}
}

extension PinpadViewController {
	static func adamantPinpad(biometryButton: PinpadBiometryButtonType) -> PinpadViewController {
		let pinpad = PinpadViewController.instantiateFromResourceNib()
		
		pinpad.bordersColor = UIColor.adamantSecondary
		pinpad.setColor(UIColor.adamantPrimary, for: .normal)
		pinpad.buttonsHighlightedColor = UIColor.adamantPinpadHighlightButton
		pinpad.buttonsFont = UIFont.adamantPrimaryLight(size: pinpad.buttonsFont.pointSize)
		pinpad.buttonsSize = 75
		pinpad.buttonsSpacing = 20
		pinpad.placeholderViewHeight = 50
		pinpad.placeholdersSize = 15
		pinpad.placeholderActiveColor = UIColor.adamantPinpadHighlightButton
		pinpad.biometryButtonType = biometryButton
		pinpad.cancelButton.setTitle(String.adamantLocalized.alert.cancel, for: .normal)
		pinpad.pinDigits = 6
		
		return pinpad
	}
}
