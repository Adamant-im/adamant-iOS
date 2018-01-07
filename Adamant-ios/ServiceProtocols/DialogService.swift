//
//  DialogService.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 07.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

protocol DialogService {
	/// Present view controller modally
	func presentViewController(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
	
	/// Create storyboard and present initial view controller with injected dependencies
	///
	/// - Parameters:
	///   - storyboardName: Storyboard name
	///   - viewControllerIdentifier: view controller identifier. If nil - initial view controller
	///   - animated: present animated
	///   - completion: Block to perform after presenting is finished
	/// - Returns: Presented View controller
	func presentStoryboard(_ storyboardName: String, viewControllerIdentifier: String?, animated: Bool, completion: (() -> Void)?) -> UIViewController
	
	func storyboard(named: String) -> UIStoryboard?
}
