//
//  SimpleDialogService.swift
//  Cosmeteria
//
//  Created by Павел Анохов on 31.08.17.
//  Copyright © 2017 METASHARKS. All rights reserved.
//

import UIKit
import SwinjectStoryboard

class SwinjectedDialogService: DialogService {
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
	
	func presentStoryboard(_ storyboardName: String, viewControllerIdentifier: String?, animated: Bool, completion: (() -> Void)?) -> UIViewController {
		let storyboard = SwinjectStoryboard.create(name: storyboardName, bundle: nil)
		
		let viewController: UIViewController
		
		if let identifier = viewControllerIdentifier {
			viewController = storyboard.instantiateViewController(withIdentifier: identifier)
		} else {
			viewController = storyboard.instantiateInitialViewController()!
		}
		
		presentViewController(viewController, animated: animated, completion: completion)
		return viewController
	}
	
	func storyboard(named name: String) -> UIStoryboard? {
		return SwinjectStoryboard.create(name: name, bundle: nil)
	}
}
