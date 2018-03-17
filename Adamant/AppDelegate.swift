//
//  AppDelegate.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject

extension String.adamantLocalized {
	struct tabItems {
		static let account = NSLocalizedString("Tabs.Account", comment: "Main tab bar: Account page")
		static let chats = NSLocalizedString("Tabs.Chats", comment: "Main tab bar: Chats page")
		static let settings = NSLocalizedString("Tabs.Settings", comment: "Main tab bar: Settings page")
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var repeater: RepeaterService!
	var container: Container!
	
	weak var accountService: AccountService?
	weak var notificationService: NotificationsService?

	// MARK: - Lifecycle
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// MARK: 1. Initiating Swinject
		container = Container()
		container.registerAdamantServices()
		accountService = container.resolve(AccountService.self)
		notificationService = container.resolve(NotificationsService.self)
		
		
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
			let accountRoot = router.get(scene: AdamantScene.Account.account)
			let account = UINavigationController(rootViewController: accountRoot)
			account.tabBarItem.title = String.adamantLocalized.tabItems.account
			account.tabBarItem.image = #imageLiteral(resourceName: "wallet_tab")
			
			let chatListRoot = router.get(scene: AdamantScene.Chats.chatList)
			let chatList = UINavigationController(rootViewController: chatListRoot)
			chatList.tabBarItem.title = String.adamantLocalized.tabItems.chats
			chatList.tabBarItem.image = #imageLiteral(resourceName: "chats_tab")
			
			let settingsRoot = router.get(scene: AdamantScene.Settings.settings)
			let settings = UINavigationController(rootViewController: settingsRoot)
			settings.tabBarItem.title = String.adamantLocalized.tabItems.settings
			settings.tabBarItem.image = #imageLiteral(resourceName: "settings_tab")
			
			
			account.tabBarItem.badgeColor = UIColor.adamantPrimary
			chatList.tabBarItem.badgeColor = UIColor.adamantPrimary
			settings.tabBarItem.badgeColor = UIColor.adamantPrimary
			
			tabbar.setViewControllers([account, chatList, settings], animated: false)
		}

		
		// MARK: 3. Initiate login
		let login = router.get(scene: AdamantScene.Login.login)
		self.window!.rootViewController?.present(login, animated: false, completion: nil)
		
		
		// MARK: 4 Autoupdate
		repeater = RepeaterService()
		if let chatsProvider = container.resolve(ChatsProvider.self),
			let transfersProvider = container.resolve(TransfersProvider.self),
			let accountService = container.resolve(AccountService.self) {
			repeater.registerForegroundCall(label: "chatsProvider", interval: 3, queue: .global(qos: .utility), callback: chatsProvider.update)
			repeater.registerForegroundCall(label: "transfersProvider", interval: 15, queue: .global(qos: .utility), callback: transfersProvider.update)
			repeater.registerForegroundCall(label: "accountService", interval: 15, queue: .global(qos: .utility), callback: accountService.update)
		} else {
			fatalError("Failed to get chatsProvider")
		}
		
		
		// MARK: 4. Notifications
		if let service = container.resolve(NotificationsService.self) {
			if service.notificationsEnabled {
				UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
			} else {
				UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
			}
			
			NotificationCenter.default.addObserver(forName: Notification.Name.adamantShowNotificationsChanged, object: service, queue: OperationQueue.main) { _ in
				if service.notificationsEnabled {
					UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
				} else {
					UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
				}
			}
		}
		
		
		// MARK: 5. Logout reset
		NotificationCenter.default.addObserver(forName: Notification.Name.adamantUserLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			// On logout, pop all navigators to root.
			guard let tbc = self?.window?.rootViewController as? UITabBarController, let vcs = tbc.viewControllers else {
				return
			}
			
			for case let nav as UINavigationController in vcs {
				nav.popToRootViewController(animated: false)
			}
		}
		
		return true
	}
	
	// MARK: Timers
	
	func applicationWillResignActive(_ application: UIApplication) {
		repeater.pauseAll()
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		repeater.pauseAll()
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		repeater.resumeAll()
		
		if accountService?.account != nil {
			notificationService?.removeAllDeliveredNotifications()
		}
	}
}


// MARK: - BackgroundFetch
extension AppDelegate {
	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		let container = Container()
		container.registerAdamantBackgroundFetchServices()
		
		guard let notificationsService = container.resolve(NotificationsService.self) else {
				UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
				completionHandler(.failed)
				return
		}
		
		let services: [BackgroundFetchService] = [
			container.resolve(ChatsProvider.self) as! BackgroundFetchService,
			container.resolve(TransfersProvider.self) as! BackgroundFetchService
		]
		
		let group = DispatchGroup()
		let semaphore = DispatchSemaphore(value: 1)
		var results = [FetchResult]()
		
		for service in services {
			group.enter()
			service.fetchBackgroundData(notificationService: notificationsService) { result in
				defer {
					group.leave()
				}
				
				semaphore.wait()
				results.append(result)
				semaphore.signal()
			}
		}
		
		group.wait()
		
		for result in results {
			switch result {
			case .newData:
				completionHandler(.newData)
				return
				
			case .noData:
				break
				
			case .failed:
				completionHandler(.failed)
				return
			}
		}
		
		completionHandler(.noData)
	}}
