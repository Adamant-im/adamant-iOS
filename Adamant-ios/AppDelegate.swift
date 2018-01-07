//
//  AppDelegate.swift
//  Adamant-ios
//
//  Created by Павел Анохов on 05.01.2018.
//  Copyright © 2018 adamant. All rights reserved.
//

import UIKit
import Swinject
import SwinjectStoryboard

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
		container.registerAdamantServices(coreJsUrl: jsCore, utilitiesJsUrl: jsUtilites)
		container.registerAdamantLoginStory()
		
		// Present UI
		presentStoryboard("Main")
		guard let loginService = container.resolve(LoginService.self) else {
			fatalError("Failed to get LoginService")
		}
		
		loginService.logoutAndPresentLoginStoryboard(animated: false, authorizationFinishedHandler: nil)
		NotificationCenter.default.addObserver(forName: .userHasLoggedIn, object: nil, queue: nil) { _ in
			print("User logged in: \(loginService.loggedAccount!)!")
		}
		
		return true
	}
	
	private func presentStoryboard(_ storyboardName: String) {
		self.window = UIWindow(frame: UIScreen.main.bounds)
		
		let storyboard = SwinjectStoryboard.create(name: storyboardName, bundle: nil)
		self.window!.rootViewController = storyboard.instantiateInitialViewController()
		self.window!.makeKeyAndVisible()
	}
}
