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
	static let apiUrl = URL(string: "https://endless.adamant.im")!
	static let chatModels = "ChatModels"
	
	private init() {}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?

	// MARK: - Lifecycle
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// Getting resources
		guard let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js"),
			let modelUrl = Bundle.main.url(forResource: Constants.chatModels, withExtension: "momd"),
			let knownContactsUrl = Bundle.main.url(forResource: "knownContacts", withExtension: "json") else {
			fatalError("Can't load system resources!")
		}
		
		// Initiating Swinject
		let container = SwinjectStoryboard.defaultContainer
		Container.loggingFunction = nil // Logging currently not supported with SwinjectStoryboards.
		container.registerAdamantServices(apiUrl: Constants.apiUrl, coreJsUrl: jsCore, managedObjectModel: modelUrl, knownContacts: knownContactsUrl)
		container.registerAdamantAccountStory()
		container.registerAdamantLoginStory()
		container.registerAdamantChatsStory()
		
		// Prepare UI
		self.window = UIWindow(frame: UIScreen.main.bounds)
		self.window!.rootViewController = SwinjectStoryboard.create(name: Constants.mainStoryboard, bundle: nil).instantiateInitialViewController()
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

// Initiate login
		
		guard let accountService = container.resolve(AccountService.self) else {
			fatalError("Failed to get AccountService")
		}
		
		accountService.logoutAndPresentLoginStoryboard(animated: false, authorizationFinishedHandler: nil)
		
		return true
	}
}
