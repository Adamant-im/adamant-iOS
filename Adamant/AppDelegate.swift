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
		
		// MARK: 1. Initiating Swinject
		let container = SwinjectStoryboard.defaultContainer
		Container.loggingFunction = nil // Logging currently not supported with SwinjectStoryboards.
		container.registerAdamantServices()
		container.registerAdamantAccountStory()
		container.registerAdamantLoginStory()
		container.registerAdamantChatsStory()
		container.registerAdamantSettingsStory()
		
		
		// MARK: 2. Prepare UI
		self.window = UIWindow(frame: UIScreen.main.bounds)
		self.window!.rootViewController = UITabBarController()
		self.window!.rootViewController?.view.backgroundColor = .white
		self.window!.makeKeyAndVisible()

		self.window!.tintColor = UIColor.adamantPrimary

		guard let router = container.resolve(Router.self) else {
			fatalError("Failed to get Router")
		}

		if let tabbar = self.window!.rootViewController as? UITabBarController {
			let account = router.get(story: .Account).instantiateInitialViewController()!
			let chats = router.get(story: .Chats).instantiateInitialViewController()!
			let settings = router.get(story: .Settings).instantiateInitialViewController()!

			tabbar.setViewControllers([account, chats, settings], animated: false)
		}

		
		// MARK: 3. Initiate login
		guard let accountService = container.resolve(AccountService.self) else {
			fatalError("Failed to get AccountService")
		}
		
		accountService.logoutAndPresentLoginStoryboard(animated: false, authorizationFinishedHandler: nil)
		
		
		// MARK: 4 Autoupdate
		let chatsProvider = container.resolve(ChatsProvider.self)!
		let repeater = RepeaterService()
		repeater.registerForegroundCall(label: "chatsProvider", interval: 3, queue: DispatchQueue.global(qos: .utility), callback: chatsProvider.update)
		
		
		// MARK: 4. On logout, pop all navigators to root.
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			guard let tbc = self?.window?.rootViewController as? UITabBarController, let vcs = tbc.viewControllers else {
				return
			}
			
			for case let nav as UINavigationController in vcs {
				nav.popToRootViewController(animated: false)
			}
		}
		
		return true
	}
}
