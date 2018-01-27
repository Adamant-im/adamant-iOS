//
//  AppDelegate.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import SwinjectStoryboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?

	// MARK: - Lifecycle
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// MARK: Initiating Swinject
		let container = SwinjectStoryboard.defaultContainer
		Container.loggingFunction = nil // Logging currently not supported with SwinjectStoryboards.
		container.registerAdamantServices()
		container.registerAdamantAccountStory()
		container.registerAdamantLoginStory()
		container.registerAdamantChatsStory()
		
		
		// MARK: Prepare UI
		self.window = UIWindow(frame: UIScreen.main.bounds)
		self.window!.rootViewController = SwinjectStoryboard.create(name: "Main", bundle: nil).instantiateInitialViewController()
		self.window!.rootViewController?.view.backgroundColor = .white
		self.window!.makeKeyAndVisible()

		self.window!.tintColor = UIColor.adamantPrimary

		guard let router = container.resolve(Router.self) else {
			fatalError("Failed to get Router")
		}

		if let tabbar = self.window!.rootViewController as? UITabBarController {
			let account = router.get(story: .Account).instantiateInitialViewController()!
			let chats = router.get(story: .Chats).instantiateInitialViewController()!

			tabbar.setViewControllers([account, chats], animated: false)
		}

		
		// MARK: Initiate login
		guard let accountService = container.resolve(AccountService.self) else {
			fatalError("Failed to get AccountService")
		}
		
		accountService.logoutAndPresentLoginStoryboard(animated: false, authorizationFinishedHandler: nil)
		
		return true
	}
}
