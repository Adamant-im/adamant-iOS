//
//  SimpleDialogService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FTIndicator

class SwinjectedDialogService: DialogService {
	// Configure notifications
	init() {
		FTIndicator.setIndicatorStyle(.dark)
	}
	
	func presentViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
		DispatchQueue.main.async {
			if var topController = UIApplication.shared.keyWindow?.rootViewController {
				while let presentedViewController = topController.presentedViewController {
					topController = presentedViewController
				}
				
				topController.present(viewController, animated: animated, completion: completion)
			} else {
				print("DialogService: Can't get root view controller!")
			}
		}
	}
}


// MARK: - Toast
extension SwinjectedDialogService {
	func showToastMessage(_ message: String) {
		FTIndicator.showToastMessage(message)
	}
}


// MARK: - Indicators
extension SwinjectedDialogService {
	func showProgress(withMessage message: String, userInteractionEnable enabled: Bool) {
		FTIndicator.showProgress(withMessage: message, userInteractionEnable: enabled)
	}
	
	func showSuccess(withMessage message: String) {
		FTIndicator.showSuccess(withMessage: message)
	}
	
	func showError(withMessage message: String) {
		showError(withMessage: message)
	}
}
