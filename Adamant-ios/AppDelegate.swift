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
		
		// Initiating Swinject
		let container = SwinjectStoryboard.defaultContainer
		Container.loggingFunction = nil // Logging currently not supported with SwinjectStoryboards.
		container.registerAdamantServices()
		
		// Present UI
		presentStoryboard("Login")
		
		return true
	}
	
	private func presentStoryboard(_ storyboardName: String) {
		self.window = UIWindow(frame: UIScreen.main.bounds)
		
		let storyboard = SwinjectStoryboard.create(name: storyboardName, bundle: nil)
		self.window!.rootViewController = storyboard.instantiateInitialViewController()
		self.window!.makeKeyAndVisible()
	}
}
