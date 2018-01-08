//
//  AppDelegate.swift
//  Adamant-ios
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import SwinjectStoryboard

private struct Constants {
	static let mainStoryboard = "Main"
	static let apiUrl = URL(string: "https://endless.adamant.im/api/")!
	
	private init() {}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?

	// MARK: - Lifecycle
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// Finding resources
		guard let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js"),
			let jsUtilites = Bundle.main.url(forResource: "utilites", withExtension: "js") else {
			fatalError("Can't load system resources!")
		}
		
		// Initiating Swinject
		let container = SwinjectStoryboard.defaultContainer
		Container.loggingFunction = nil // Logging currently not supported with SwinjectStoryboards.
		container.registerAdamantServices(apiUrl: Constants.apiUrl, coreJsUrl: jsCore, utilitiesJsUrl: jsUtilites)
		container.registerAdamantLoginStory()
		container.registerAdamantAccountStory()
		
		// Prepare UI
		self.window = UIWindow(frame: UIScreen.main.bounds)
		self.window!.rootViewController = SwinjectStoryboard.create(name: Constants.mainStoryboard, bundle: nil).instantiateInitialViewController()
		self.window!.makeKeyAndVisible()
		
		guard let router = container.resolve(Router.self) else {
			fatalError("Failed to get Router")
		}
		
		if let tabbar = self.window!.rootViewController as? UITabBarController {
			let vc = router.get(story: .Account).instantiateInitialViewController()!
			tabbar.setViewControllers([vc], animated: false)
		}

// Initiate login
		
		guard let loginService = container.resolve(LoginService.self) else {
			fatalError("Failed to get LoginService")
		}
		
		loginService.logoutAndPresentLoginStoryboard(animated: false, authorizationFinishedHandler: nil)
		NotificationCenter.default.addObserver(forName: .userHasLoggedIn, object: nil, queue: nil) { _ in
			print("User logged in: \(loginService.loggedAccount!)!")
		}
		
		return true
	}
}
