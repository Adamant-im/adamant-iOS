//
//  AdamantDialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import FTIndicator

class AdamantDialogService: DialogService {
	// Configure notifications
	init() {
		FTIndicator.setIndicatorStyle(.dark)
	}
}


// MARK: - Modal dialogs
extension AdamantDialogService {
	func presentModallyViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
		if Thread.isMainThread {
			AdamantDialogService.getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
		} else {
			DispatchQueue.main.async {
				AdamantDialogService.getTopmostViewController()?.present(viewController, animated: animated, completion: completion)
			}
		}
	}
	
	private static func getTopmostViewController() -> UIViewController? {
		if var topController = UIApplication.shared.keyWindow?.rootViewController {
			while let presentedViewController = topController.presentedViewController {
				topController = presentedViewController
			}
			
			return topController
		}
		
		return nil
	}
}


// MARK: - Toast
extension AdamantDialogService {
	func showToastMessage(_ message: String) {
		FTIndicator.showToastMessage(message)
	}
}


// MARK: - Indicators
extension AdamantDialogService {
	func showProgress(withMessage message: String, userInteractionEnable enabled: Bool) {
		FTIndicator.showProgress(withMessage: message, userInteractionEnable: enabled)
	}
	
	func showSuccess(withMessage message: String) {
		FTIndicator.showSuccess(withMessage: message)
	}
	
	func showError(withMessage message: String) {
		FTIndicator.showError(withMessage: message)
	}
}
