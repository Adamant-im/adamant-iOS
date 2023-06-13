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
import Firebase

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
    var visibleWalletsService: VisibleWalletsService!
    
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
        visibleWalletsService = container.resolve(VisibleWalletsService.self)
        
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
        rootTabBarController.view.backgroundColor = .adamant.backgroundColor
        window.tintColor = UIColor.adamant.primary
        
        // MARK: 3. Prepare pages
        guard let router = container.resolve(Router.self) else {
            fatalError("Failed to get Router")
        }
        
        let chatList = UINavigationController(
            rootViewController: router.get(scene: AdamantScene.Chats.chatList)
        )
        
        let account = UINavigationController(
            rootViewController: router.get(scene: AdamantScene.Account.account)
        )
        
        let tabScreens: TabScreens = UIScreen.main.traitCollection.userInterfaceIdiom == .pad
            ? .splitControllers(makeSplitController(), makeSplitController())
            : .navigationControllers(chatList, account)
        
        tabScreens.viewControllers.0.tabBarItem.title = .adamantLocalized.tabItems.chats
        tabScreens.viewControllers.0.tabBarItem.image = #imageLiteral(resourceName: "chats_tab")
        tabScreens.viewControllers.0.tabBarItem.badgeColor = .adamant.primary
        
        tabScreens.viewControllers.1.tabBarItem.title = .adamantLocalized.tabItems.account
        tabScreens.viewControllers.1.tabBarItem.image = #imageLiteral(resourceName: "account-tab")
        tabScreens.viewControllers.1.tabBarItem.badgeColor = .adamant.primary
        
        let resetScreensAction: () -> Void
        switch tabScreens {
        case let .splitControllers(leftController, rightController):
            resetScreensAction = {
                let chatDetails = WelcomeViewController()
                let accountDetails = WelcomeViewController()
                leftController.viewControllers = [chatList, chatDetails]
                rightController.viewControllers = [account, accountDetails]
            }
        case let .navigationControllers(leftController, rightController):
            resetScreensAction = {
                leftController.popToRootViewController(animated: false)
                rightController.popToRootViewController(animated: false)
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
        
        rootTabBarController.setViewControllers(
            tabScreens.arrayOfViewControllers,
            animated: false
        )
        
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
        
        // Setup transactions statuses observing
        if let service = container.resolve(RichTransactionStatusService.self) {
            Task { await service.startObserving() }
        }
        
        // Setup transactions reply observing
        if let service = container.resolve(RichTransactionReplyService.self) {
            Task { await service.startObserving() }
        }
        
        // Register repeater services
        if let chatsProvider = container.resolve(ChatsProvider.self) {
            repeater.registerForegroundCall(label: "chatsProvider", interval: 10, queue: .global(qos: .utility), callback: {
                Task {
                    await chatsProvider.update(notifyState: false)
                }
            })
            
        } else {
            dialogService.showError(withMessage: "Failed to register ChatsProvider autoupdate. Please, report a bug", supportEmail: true, error: nil)
        }
        
        if let transfersProvider = container.resolve(TransfersProvider.self) {
            repeater.registerForegroundCall(label: "transfersProvider", interval: 15, queue: .global(qos: .utility), callback: {
                Task {
                    await transfersProvider.update()
                }
            })
        } else {
            dialogService.showError(withMessage: "Failed to register TransfersProvider autoupdate. Please, report a bug", supportEmail: true, error: nil)
        }
        
        if let accountService = container.resolve(AccountService.self) {
            repeater.registerForegroundCall(label: "accountService", interval: 15, queue: .global(qos: .utility), callback: accountService.update)
        } else {
            dialogService.showError(withMessage: "Failed to register AccountService autoupdate. Please, report a bug", supportEmail: true, error: nil)
        }
        
        if let addressBookService = container.resolve(AddressBookService.self) {
            repeater.registerForegroundCall(label: "addressBookService", interval: 15, queue: .global(qos: .utility), callback: {
                Task {
                    await addressBookService.update()
                }
            })
        } else {
            dialogService.showError(withMessage: "Failed to register AddressBookService autoupdate. Please, report a bug", supportEmail: true, error: nil)
        }
        
        if let currencyInfoService = container.resolve(CurrencyInfoService.self) {
            currencyInfoService.update() // Initial update
            repeater.registerForegroundCall(label: "currencyInfoService", interval: 60, queue: .global(qos: .utility), callback: currencyInfoService.update)
        } else {
            dialogService.showError(withMessage: "Failed to register CurrencyInfoService autoupdate. Please, report a bug", supportEmail: true, error: nil)
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
        Task {
            for await notification in NotificationCenter.default.notifications(
                named: .AdamantChatsProvider.initiallySyncedChanged
            ) {
                await self.handleWelcomeMessages(notification: notification)
            }
        }
        
        // MARK: 9. Notifications
        pushNotificationsTokenService.sendTokenDeletionTransactions()
        UNUserNotificationCenter.current().delegate = self
        
        // MARK: Firebase
        FirebaseApp.configure()
        
        return true
    }
    
    // MARK: Timers
    
    func applicationWillResignActive(_ application: UIApplication) {
        repeater.pauseAll()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        repeater.pauseAll()
        Task {
            await addressBookService.saveIfNeeded()
        }
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
            service.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.notifications.registerRemotesError, error.localizedDescription), supportEmail: true, error: error)
        }
    }
    
    func openDialog(
        chatListNav: UINavigationController,
        tabbar: UITabBarController,
        chatListVC: ChatListViewController,
        transactionID: String,
        senderAddress: String
    ) {
        if
            let chatVCNav = chatListNav.viewControllers.last as? UINavigationController,
            let chatVC = chatVCNav.viewControllers.first as? ChatViewController,
            chatVC.viewModel.chatroom?.partner?.address == senderAddress
        {
            chatVC.messagesCollectionView.scrollToLastItem()
            return
        }
        
        if
            let chatVC = chatListNav.viewControllers.last as? ChatViewController,
            chatVC.viewModel.chatroom?.partner?.address == senderAddress
        {
            chatVC.messagesCollectionView.scrollToLastItem()
            return
        }
        
        let chatroom = chatListVC.chatsController?.fetchedObjects?.first(
            where: {
                $0.partner?.address == senderAddress
            }
        )
        
        guard let chatroom = chatroom else { return }
        
        chatListNav.popToRootViewController(animated: true)
        chatListNav.dismiss(animated: true, completion: nil)
        tabbar.selectedIndex = 0
        
        let vc = chatListVC.chatViewController(for: chatroom, with: transactionID)
                                               
        vc.hidesBottomBarWhenPushed = true
        
        if let split = chatListVC.splitViewController {
            let chat = UINavigationController(rootViewController: vc)
            split.showDetailViewController(chat, sender: chatListVC)
        } else {
            chatListNav.pushViewController(vc, animated: true)
        }
        
        chatListVC.selectChatroomRow(chatroom: chatroom)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        var chatListNav: UINavigationController?
        var chatListVC: ChatListViewController?
        
        let userInfo = response.notification.request.content.userInfo
        
        guard let transactionID = userInfo[AdamantNotificationUserInfoKeys.transactionId] as? String,
              let transactionRaw = userInfo[AdamantNotificationUserInfoKeys.transaction] as? String,
              let data = transactionRaw.data(using: .utf8),
              let trs = try? JSONDecoder().decode(Transaction.self, from: data),
              let tabbar = window?.rootViewController as? UITabBarController
        else {
            completionHandler()
            return
        }
        
        if let split = tabbar.viewControllers?.first as? UISplitViewController,
           let navigation = split.viewControllers.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatListNav = navigation
            chatListVC = vc
        }
        
        if let navigation = tabbar.viewControllers?.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatListNav = navigation
            chatListVC = vc
        }
        
        guard let chatListVC = chatListVC,
              let chatListNav = chatListNav
        else {
            completionHandler()
            return
        }
        
        chatListVC.performOnMessagesLoaded { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.dialogService.dismissProgress()
                self?.openDialog(
                    chatListNav: chatListNav,
                    tabbar: tabbar,
                    chatListVC: chatListVC,
                    transactionID: transactionID,
                    senderAddress: trs.senderId
                )
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
        
        Task {
            let results = await fetchBackgroundData(notificationsService: notificationsService)
            
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
    
    func fetchBackgroundData(notificationsService: NotificationsService) async -> [FetchResult] {
        let services: [BackgroundFetchService] = [
            container.resolve(ChatsProvider.self) as! BackgroundFetchService,
            container.resolve(TransfersProvider.self) as! BackgroundFetchService
        ]
        
        return await withTaskGroup(of: FetchResult.self) { group in
            for case let service in services {
                group.addTask {
                    let result = await service.fetchBackgroundData(notificationsService: notificationsService)
                    return result
                }
            }
            
            var results: [FetchResult] = []
            
            for await result in group {
                results.append(result)
            }

            return results
        }
    }
}

// MARK: - Welcome messages
extension AppDelegate {
    @MainActor
    private func handleWelcomeMessages(notification: Notification) async {
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
        
        if let adelina = AdamantContacts.adelina.messages["chats.welcome_message"] {
            _ = try? await chatProvider.fakeReceived(
                message: adelina.message,
                senderId: AdamantContacts.adelina.address,
                date: Date.adamantNullDate,
                unread: false,
                silent: adelina.silentNotification,
                showsChatroom: true
            )
        }
        
        if let exchenge = AdamantContacts.adamantExchange.messages["chats.welcome_message"] {
            _ = try? await chatProvider.fakeReceived(
                message: exchenge.message,
                senderId: AdamantContacts.adamantExchange.address,
                date: Date.adamantNullDate,
                unread: false,
                silent: exchenge.silentNotification,
                showsChatroom: true
            )
        }
        
        if let betOnBitcoin = AdamantContacts.betOnBitcoin.messages["chats.welcome_message"] {
            _ = try? await chatProvider.fakeReceived(
                message: betOnBitcoin.message,
                senderId: AdamantContacts.betOnBitcoin.address,
                date: Date.adamantNullDate,
                unread: false,
                silent: betOnBitcoin.silentNotification,
                showsChatroom: false
            )
        }
        
        if let welcome = AdamantContacts.donate.messages["chats.welcome_message"] {
            _ = try? await chatProvider.fakeReceived(
                message: welcome.message,
                senderId: AdamantContacts.donate.address,
                date: Date.adamantNullDate,
                unread: false,
                silent: true,
                showsChatroom: true
            )
        }
        
        if let welcome = AdamantContacts.adamantWelcomeWallet.messages["chats.welcome_message"] {
            _ = try? await chatProvider.fakeReceived(
                message: welcome.message,
                senderId: AdamantContacts.adamantWelcomeWallet.name,
                date: Date.adamantNullDate,
                unread: unread,
                silent: welcome.silentNotification,
                showsChatroom: true
            )
        }
    }
}

// MARK: - Universal Links
extension AppDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        processDeepLink(url)
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else {
            return true
        }
        
        processDeepLink(url)
        return true
    }
    
    func processDeepLink(_ url: URL) {
        var adamantAdr: AdamantAddress? = url.absoluteString.getAdamantAddress()
        
        if adamantAdr == nil {
            adamantAdr = url.absoluteString.getLegacyAdamantAddress()
        }
        
        guard let adamantAdr = adamantAdr else {
            return
        }
        
        var chatList: UINavigationController?
        var chatDetail: ChatListViewController?
        
        guard let tabbar = window?.rootViewController as? UITabBarController,
              let router = container.resolve(Router.self)
        else {
            return
        }
        
        if let split = tabbar.viewControllers?.first as? UISplitViewController,
           let navigation = split.viewControllers.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatList = navigation
            chatDetail = vc
        }
        
        if let navigation = tabbar.viewControllers?.first as? UINavigationController,
           let vc = navigation.viewControllers.first as? ChatListViewController {
            chatList = navigation
            chatDetail = vc
        }
        
        guard let chatList = chatList,
              let chatDetail = chatDetail
        else {
            return
        }
        
        chatDetail.performOnMessagesLoaded { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.startNewDialog(
                    with: adamantAdr,
                    chatList: chatList,
                    tabbar: tabbar,
                    router: router,
                    chatDetail: chatDetail
                )
            }
        }
    }
    
    func startNewDialog(
        with adamantAdr: AdamantAddress,
        chatList: UINavigationController,
        tabbar: UITabBarController,
        router: Router,
        chatDetail: ChatListViewController
    ) {
        chatList.popToRootViewController(animated: false)
        chatList.dismiss(animated: false, completion: nil)
        tabbar.selectedIndex = 0
        
        let newChat = router.get(scene: AdamantScene.Chats.newChat) as? NewChatViewController

        guard let newChat = newChat else { return }

        newChat.delegate = chatDetail.self
        
        if let split = chatDetail.splitViewController {
            split.showDetailViewController(newChat, sender: chatDetail.self)
        } else if let nav = chatDetail.navigationController {
            nav.pushViewController(newChat, animated: true)
        } else {
            newChat.modalPresentationStyle = .overFullScreen
            chatDetail.present(newChat, animated: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            newChat.startNewChat(with: adamantAdr.address, name: adamantAdr.name, message: adamantAdr.message)
        }
    }
}

private enum TabScreens {
    case splitControllers(UISplitViewController, UISplitViewController)
    case navigationControllers(UINavigationController, UINavigationController)
    
    var viewControllers: (UIViewController, UIViewController) {
        switch self {
        case let .splitControllers(leftController, rightController):
            return (leftController, rightController)
        case let .navigationControllers(leftController, rightController):
            return (leftController, rightController)
        }
    }
    
    var arrayOfViewControllers: [UIViewController] {
        switch self {
        case let .splitControllers(leftController, rightController):
            return [leftController, rightController]
        case let .navigationControllers(leftController, rightController):
            return [leftController, rightController]
        }
    }
}

private func makeSplitController() -> UISplitViewController {
    let controller = UISplitViewController()
    controller.preferredDisplayMode = .oneBesideSecondary
    return controller
}
