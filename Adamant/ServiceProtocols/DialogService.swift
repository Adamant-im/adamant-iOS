//
//  DialogService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

protocol DialogService {
	/// Present view controller modally
	func presentModallyViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
	
	
	// MARK: - Toast messages
	/// Show pop-up message
	func showToastMessage(_ message: String)
	
	
	// MARK: - Indicators
	func showProgress(withMessage: String, userInteractionEnable: Bool)
	func showSuccess(withMessage: String)
	func showError(withMessage: String)
}
