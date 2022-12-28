//
//  AppDelegate.swift
//  Adamant
//
//  Created by Anokhov Pavel on 05.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit
import Swinject
import CryptoSwift
import CoreData

// MARK: - Constants
extension String.adamantLocalized {
    struct tabItems {
        static let account = NSLocalizedString("Tabs.Account", comment: "Main tab bar: Account page")
        static let chats = NSLocalizedString("Tabs.Chats", comment: "Main tab bar: Chats page")
        static let settings = NSLocalizedString("Tabs.Settings", comment: "Main tab bar: Settings page")
    }
    
    struct application {
        static let deviceTokenSendFailed = NSLocalizedString("Application.deviceTokenErrorFormat", comment: "Application: Failed to send deviceToken to ANS error format. %@ for error description")
    }
}

extension StoreKey {
    struct application {
        static let welcomeScreensIsShown = "app.welcomeScreensIsShown"
        static let eulaAccepted = "app.eulaAccepted"
        static let firstRun = "app.firstRun"
        
        private init() {}
    }
}

// MARK: - Application
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var repeater: RepeaterService!
    var container: Container!
    
    // MARK: Dependencies
    var accountService: AccountService!
    var notificationService: NotificationsService!
    var dialogService: DialogService!
    var addressBookService: AddressBookService!
    var pushNotificationsTokenService: PushNotificationsTokenService!

    // MARK: - Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // MARK: 0. Migrate keychain if needed
        KeychainStore.migrateIfNeeded()
        
        // MARK: 1. Initiating Swinject
        container = Container()
        container.registerAdamantServices()
        accountService = container.resolve(AccountService.self)
        notificationService = container.resolve(NotificationsService.self)
        dialogService = container.resolve(DialogService.self)
        addressBookService = container.resolve(AddressBookService.self)
        pushNotificationsTokenService = container.resolve(PushNotificationsTokenService.self)
        
        // MARK: 1.1. First run flag
        let firstRun = UserDefaults.standard.bool(forKey: StoreKey.application.firstRun)

        if !firstRun {
            UserDefaults.standard.set(true, forKey: StoreKey.application.firstRun)

            if let securedStore = container.resolve(SecuredStore.self) {
                securedStore.purgeStore()
            }
        }
        
        // MARK: 2. Init UI
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let rootTabBarController = UITabBarController()
        window.rootViewController = rootTabBarController
        window.rootViewController!.view.backgroundColor = .white
        window.tintColor = UIColor.adamant.primary
        
        // MARK: 3. Prepare pages
        guard let router = container.resolve(Router.self) else {
            fatalError("Failed to get Router")
        }
        
        // MARK: Chats
        let chats = UISplitViewController()
        chats.tabBarItem.title = String.adamantLocalized.tabItems.chats
        chats.tabBarItem.image = #imageLiteral(resourceName: "chats_tab")
        chats.preferredDisplayMode = .oneBesideSecondary
        chats.tabBarItem.badgeColor = UIColor.adamant.primary
        
        let chatList = UINavigationController(rootViewController: router.get(scene: AdamantScene.Chats.chatList))
        
        // MARK: Accounts
        let accounts = UISplitViewController()
        accounts.tabBarItem.title = String.adamantLocalized.tabItems.account
        accounts.tabBarItem.image = #imageLiteral(resourceName: "account-tab")
        accounts.preferredDisplayMode = .oneBesideSecondary
        accounts.tabBarItem.badgeColor = UIColor.adamant.primary
        
        let account = UINavigationController(rootViewController: router.get(scene: AdamantScene.Account.account))
        
        let resetScreensAction = {
            if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
                let chatDetails = UIViewController(nibName: "WelcomeViewController", bundle: nil)
                let accountDetails = UIViewController(nibName: "WelcomeViewController", bundle: nil)
                
                chats.viewControllers = [chatList, chatDetails]
                accounts.viewControllers = [account, accountDetails]
            } else {
                chats.viewControllers = [chatList]
                accounts.viewControllers = [account]
            }
        }
        
        resetScreensAction()
        
        let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        rootTabBarController.setViewControllers([chats, accounts], animated: false)
        
        window.makeKeyAndVisible()
        
        // MARK: 4. Setup dialog service
        dialogService.setup(window: window)
        
        // MARK: 5. Show login
        let login = router.get(scene: AdamantScene.Login.login) as! LoginViewController
        let welcomeIsShown = UserDefaults.standard.bool(forKey: StoreKey.application.welcomeScreensIsShown)
        
        login.requestBiometryOnFirstTimeActive = welcomeIsShown
        login.modalPresentationStyle = .overFullScreen
        window.rootViewController?.present(login, animated: false, completion: nil)
        
        if !welcomeIsShown {
            let welcome = router.get(scene: AdamantScene.Onboard.welcome)
            welcome.modalPresentationStyle = .overFullScreen
            login.present(welcome, animated: true, completion: nil)
            UserDefaults.standard.set(true, forKey: StoreKey.application.welcomeScreensIsShown)
        }
    
        // MARK: 6 Reachability & Autoupdate
        repeater = RepeaterService()
        
        // Configure reachability
        if let reachability = container.resolve(ReachabilityMonitor.self) {
            reachability.start()
            
            if reachability.connection {
                dialogService.dissmisNoConnectionNotification()
            } else {
                dialogService.showNoConnectionNotification()
                repeater.pauseAll()
            }
            
            NotificationCenter.default.addObserver(forName: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: reachability, queue: nil) { [weak self] notification in
                guard let connection = notification.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? Bool,
                    let repeater = self?.repeater else {
                        return
                }
                
                if connection {
                    DispatchQueue.onMainSync {
                        self?.dialogService.dissmisNoConnectionNotification()
                    }
                    repeater.resumeAll()
                } else {
                    DispatchQueue.onMainSync {
                        self?.dialogService.showNoConnectionNotification()
                    }
                    repeater.pauseAll()
                }
            }
        }
        
        // Register repeater services
        if let chatsProvider = container.resolve(ChatsProvider.self) {
            repeater.registerForegroundCall(label: "chatsProvider", interval: 10, queue: .global(qos: .utility), callback: chatsProvider.update)
            
        } else {
            dialogService.showError(withMessage: "Failed to register ChatsProvider autoupdate. Please, report a bug", error: nil)
        }
        
        if let transfersProvider = container.resolve(TransfersProvider.self) {
            repeater.registerForegroundCall(label: "transfersProvider", interval: 15, queue: .global(qos: .utility), callback: transfersProvider.update)
        } else {
            dialogService.showError(withMessage: "Failed to register TransfersProvider autoupdate. Please, report a bug", error: nil)
        }
        
        if let accountService = container.resolve(AccountService.self) {
            repeater.registerForegroundCall(label: "accountService", interval: 15, queue: .global(qos: .utility), callback: accountService.update)
        } else {
            dialogService.showError(withMessage: "Failed to register AccountService autoupdate. Please, report a bug", error: nil)
        }
        
        if let addressBookService = container.resolve(AddressBookService.self) {
            repeater.registerForegroundCall(label: "addressBookService", interval: 15, queue: .global(qos: .utility), callback: addressBookService.update)
        } else {
            dialogService.showError(withMessage: "Failed to register AddressBookService autoupdate. Please, report a bug", error: nil)
        }
        
        if let currencyInfoService = container.resolve(CurrencyInfoService.self) {
            currencyInfoService.update() // Initial update
            repeater.registerForegroundCall(label: "currencyInfoService", interval: 60, queue: .global(qos: .utility), callback: currencyInfoService.update)
        } else {
            dialogService.showError(withMessage: "Failed to register CurrencyInfoService autoupdate. Please, report a bug", error: nil)
        }
        
        // MARK: 7. Logout reset
        NotificationCenter.default.addObserver(
            forName: Notification.Name.AdamantAccountService.userLoggedOut,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            resetScreensAction()
        }
        
        // MARK: 8. Welcome messages
        NotificationCenter.default.addObserver(forName: Notification.Name.AdamantChatsProvider.initiallySyncedChanged, object: nil, queue: OperationQueue.main, using: handleWelcomeMessages)
        
        // MARK: 9. Notifications
        pushNotificationsTokenService.sendTokenDeletionTransactions()
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // MARK: Timers
    
    func applicationWillResignActive(_ application: UIApplication) {
        repeater.pauseAll()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        repeater.pauseAll()
        addressBookService.saveIfNeeded()
    }
    
    // MARK: Notifications
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if accountService.account != nil {
            notificationService.removeAllDeliveredNotifications()
        }
        
        guard container.resolve(ReachabilityMonitor.self)?.connection == true
        else { return }
        
        repeater.resumeAll()
    }
}

// MARK: - Remote notifications
extension AppDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        pushNotificationsTokenService.setToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if let service = container.resolve(DialogService.self) {
            service.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.notifications.registerRemotesError, error.localizedDescription), error: error)
        }
    }
    
    func openDialog(chatList: UINavigationController, tabbar: UITabBarController, list: ChatListViewController, transactionID: String, senderAddress: String) {
        if
            let chatVCNav = chatList.viewControllers.last as? UINavigationController,
            let chatVC = chatVCNav.viewControllers.first as? ChatViewController,
            chatVC.viewModel.chatroom?.partner?.address == senderAddress
        {
            // TODO: [Chats] Implement scroll down
//            chatVC.scrollDown()
            return
        }
        
        guard let chatroom = list.chatsController?.fetchedObjects?.first(where: { room in
            let transactionExist = room.transactions?.first(where: { message in
                return (message as? ChatTransaction)?.senderAddress == senderAddress
            })
            return transactionExist != nil
        }) else { return }
        
        chatList.popToRootViewController(animated: false)
        chatList.dismiss(animated: false, completion: nil)
        tabbar.selectedIndex = 0
        
        let vc = list.chatViewController(for: chatroom)
        if let split = list.splitViewController {
            let chat = UINavigationController(rootViewController: vc)
            split.showDetailViewController(chat, sender: list)
        } else {
            chatList.pushViewController(vc, animated: false)
        }
        
        list.selectChatroomRow(chatroom: chatroom)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let transactionID = userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String,
              let transactionRaw = userInfo[AdamantNotificationUserInfoKeys.transaction] as? String,
              let data = transactionRaw.data(using: .utf8),
              let trs = try? JSONDecoder().decode(Transaction.self, from: data),
              let tabbar = window?.rootViewController as? UITabBarController,
              let chats = tabbar.viewControllers?.first as? UISplitViewController,
              let chatList = chats.viewControllers.first as? UINavigationController,
              let list = chatList.viewControllers.first as? ChatListViewController
        else {
            completionHandler()
            return
        }
        
        // if not logged in
        list.performOnMessagesLoaded { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.dialogService.dismissProgress()
                self?.openDialog(chatList: chatList, tabbar: tabbar, list: list, transactionID: transactionID, senderAddress: trs.senderId)
            }
        }
        
        completionHandler()
    }
}

// MARK: - Background Fetch
extension AppDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let container = Container()
        container.registerAdamantServices()
        
        guard let notificationsService = container.resolve(NotificationsService.self) else {
                UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
                completionHandler(.failed)
                return
        }
        
        notificationsService.startBackgroundBatchNotifications()
        
        let services: [BackgroundFetchService] = [
            container.resolve(ChatsProvider.self) as! BackgroundFetchService,
            container.resolve(TransfersProvider.self) as! BackgroundFetchService
        ]
        
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: 1)
        var results = [FetchResult]()
        
        for service in services {
            group.enter()
            service.fetchBackgroundData(notificationsService: notificationsService) { result in
                defer {
                    group.leave()
                }
                
                semaphore.wait()
                results.append(result)
                semaphore.signal()
            }
        }
        
        group.notify(queue: DispatchQueue.global(qos: .utility)) {
            notificationsService.stopBackgroundBatchNotifications()
            
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
        }
    }
}

// MARK: - Welcome messages
extension AppDelegate {
    private func handleWelcomeMessages(notification: Notification) {
        guard let synced = notification.userInfo?[AdamantUserInfoKey.ChatProvider.initiallySynced] as? Bool, synced else {
            return
        }
        
        guard let stack = container.resolve(CoreDataStack.self), let chatProvider = container.resolve(ChatsProvider.self) else {
            fatalError("Whoa...")
        }
        
        let request = NSFetchRequest<MessageTransaction>(entityName: MessageTransaction.entityName)
        
        let unread: Bool
        if let count = try? stack.container.viewContext.count(for: request), count > 0 {
            unread = false
        } else {
            unread = true
        }
        if let exchenge = AdamantContacts.adamantExchange.messages["chats.welcome_message"] {
            chatProvider.fakeReceived(message: exchenge.message,
                                      senderId: AdamantContacts.adamantExchange.address,
                                      date: Date.adamantNullDate,
                                      unread: false,
                                      silent: exchenge.silentNotification,
                                      showsChatroom: true,
                                      completion: { result in
                                        guard case let .failure(error) = result else {
                                            return
                                        }
                                        
                                        print("ERROR showing exchenge message: \(error.message)")
            })
        }
        
        if let betOnBitcoin = AdamantContacts.betOnBitcoin.messages["chats.welcome_message"] {
            chatProvider.fakeReceived(message: betOnBitcoin.message,
                                      senderId: AdamantContacts.betOnBitcoin.address,
                                      date: Date.adamantNullDate,
                                      unread: false,
                                      silent: betOnBitcoin.silentNotification,
                                      showsChatroom: true,
                                      completion: { result in
                                        guard case let .failure(error) = result else {
                                            return
                                        }
                                        
                                        print("ERROR showing exchenge message: \(error.message)")
            })
        }
        
        if let welcome = AdamantContacts.donate.messages["chats.welcome_message"] {
            chatProvider.fakeReceived(message: welcome.message,
                                      senderId: AdamantContacts.donate.address,
                                      date: Date.adamantNullDate,
                                      unread: false,
                                      silent: true,
                                      showsChatroom: true,
                                      completion: { result in
                                        guard case let .failure(error) = result else {
                                            return
                                        }
                                        
                                        print("ERROR showing donate message: \(error.message)")
            })
        }
        
        if let welcome = AdamantContacts.adamantWelcomeWallet.messages["chats.welcome_message"] {
            chatProvider.fakeReceived(message: welcome.message,
                                      senderId: AdamantContacts.adamantWelcomeWallet.name,
                                      date: Date.adamantNullDate,
                                      unread: unread,
                                      silent: welcome.silentNotification,
                                      showsChatroom: true,
                                      completion: { result in
                                        guard case let .failure(error) = result else {
                                            return
                                        }
                                        
                                        print("ERROR showing welcome message: \(error.message)")
            })
        }
        
        /*
        if let ico = AdamantContacts.adamantIco.messages["chats.ico_message"] {
            chatProvider.fakeReceived(message: ico.message,
                                      senderId: AdamantContacts.adamantIco.name,
                                      date: Date.adamantNullDate,
                                      unread: unread,
                                      silent: ico.silentNotification,
                                      showsChatroom: true,
                                      completion: { result in
                                        guard case let .failure(error) = result else {
                                            return
                                        }
                                        
                                        print("ERROR showing welcome message: \(error.message)")
            })
        }
        */
    }
}

// MARK: - Universal Links
extension AppDelegate {
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            let url = userActivity.webpageURL
            if let adamantAdr = url?.absoluteString.getAdamantAddress() {
                if let tabbar = window?.rootViewController as? UITabBarController,
                   let chats = tabbar.viewControllers?.first as? UISplitViewController,
                   let chatList = chats.viewControllers.first as? UINavigationController,
                   let router = container.resolve(Router.self),
                   let list = chatList.viewControllers.first as? ChatListViewController {
                 
                    // if not logged in
                    list.performOnMessagesLoaded { [weak self] in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self?.openDialog(chatList: chatList, tabbar: tabbar, router: router, list: list, adamantAdr: adamantAdr)
                        }
                    }
                }
                
            }
        }
        return true
    }
    
    func openDialog(chatList: UINavigationController, tabbar: UITabBarController, router: Router, list: ChatListViewController, adamantAdr: AdamantAddress) {
        chatList.popToRootViewController(animated: false)
        chatList.dismiss(animated: false, completion: nil)
        tabbar.selectedIndex = 0
        
        let controller = router.get(scene: AdamantScene.Chats.newChat)
        guard let nav = controller as? UINavigationController,
              let c = nav.viewControllers.last as? NewChatViewController else {
                  return
              }
        
        c.delegate = list.self
        
        if let split = list.splitViewController {
            split.showDetailViewController(controller, sender: list.self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                c.startNewChat(with: adamantAdr.address, name: adamantAdr.name, message: adamantAdr.message)
            }
        }
    }
}
