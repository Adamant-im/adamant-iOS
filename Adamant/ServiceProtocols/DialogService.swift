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
	
	/// Show pop-up message
	func showToastMessage(_ message: String)
}
