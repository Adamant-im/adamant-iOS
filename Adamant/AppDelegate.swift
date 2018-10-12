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

import Stylist
import MyLittlePinpad
import Parchment

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
		static let deviceTokenHash = "app.deviceTokenHash"
		
		private init() {}
	}
}


// MARK: - Resources
struct AdamantResources {
	static let jsCore = Bundle.main.url(forResource: "adamant-core", withExtension: "js")!
	static let coreDataModel = Bundle.main.url(forResource: "ChatModels", withExtension: "momd")!
	
	static let nodes: [Node] = [
		Node(scheme: .https, host: "endless.adamant.im", port: nil),
		Node(scheme: .https, host: "clown.adamant.im", port: nil),
		Node(scheme: .https, host: "lake.adamant.im", port: nil),
//		Node(scheme: .http, host: "80.211.177.181", port: nil), // Bugged one
//		Node(scheme: .http, host: "163.172.183.198", port: nil) // Testnet
	]
    
    static let ethServers = [
//        "https://ethnode1.adamant.im/"
        "https://ropsten.infura.io/"  // test network
    ]
	
	// Addresses
	static let supportEmail = "ios@adamant.im"
	static let ansReadmeUrl = "https://github.com/Adamant-im/AdamantNotificationService/blob/master/README.md"
	
	// Contacts
	struct contacts {
		static let adamantBountyWallet = "U15423595369615486571"
		static let adamantIco = "U7047165086065693428"
		static let iosSupport = "U15738334853882270577"
		
		static let ansAddress = "U10629337621822775991"
		static let ansPublicKey = "188b24bd116a556ac8ba905bbbdaa16e237dfb14269f5a4f9a26be77537d977c"
		
		private init() {}
	}
    
    // Explorers
    static let adamantExplorerAddress = "https://explorer.adamant.im/tx/"
//    static let ethereumExplorerAddress = "https://etherscan.io/tx/"
    static let ethereumExplorerAddress = "https://ropsten.etherscan.io/tx/" // Testnet
	
	private init() {}
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
    
    var themes: [String: Theme] = [:]

	// MARK: - Lifecycle
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// MARK: 1. Initiating Swinject
		container = Container()
		container.registerAdamantServices()
		accountService = container.resolve(AccountService.self)
		notificationService = container.resolve(NotificationsService.self)
        dialogService = container.resolve(DialogService.self)
        addressBookService = container.resolve(AddressBookService.self)
		
		// MARK: 2. Init UI
		window = UIWindow(frame: UIScreen.main.bounds)
		window!.rootViewController = UITabBarController()
		window!.rootViewController?.view.backgroundColor = .white
		window!.makeKeyAndVisible()
		window!.tintColor = UIColor.adamant.primary
		
        print("Strat loading themes")
        if let path = Bundle.main.path(forResource: "ThemeLight", ofType: "yaml") {
            do {
                let theme = try Theme(path: path)
                self.themes["light"] = theme
            } catch {
                print("\(error)")
            }
        }
        
        if let path = Bundle.main.path(forResource: "ThemeDark", ofType: "yaml") {
            do {
                let theme = try Theme(path: path)
                self.themes["dark"] = theme
            } catch {
                print("\(error)")
            }
        }
        print("Stop loading themes")
        
        // adds custom properties to Stylist
        Stylist.shared.addProperty(StyleProperty(name: "separatorColor") { (view: UITableView, value: PropertyValue<UIColor>) in
            view.separatorColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "placeholderColor") { (view: UITextField, value: PropertyValue<UIColor>) in
            if let placeholder = view.placeholder {
                view.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: value.value])
            }
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "clearButtonTintColor") { (view: UITextField, value: PropertyValue<UIColor>) in
            view.clearButtonTint = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "showDarkKeyboard") { (view: UITextField, value: PropertyValue<Bool>) in
            view.keyboardAppearance = value.value ? .dark : .light
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "highlightedBackgroundColor") { (view: RoundedButton, value: PropertyValue<UIColor>) in
            view.highlightedBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "normalBackgroundColor") { (view: RoundedButton, value: PropertyValue<UIColor>) in
            view.normalBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "avatarTintColor") { (view: ChatTableViewCell, value: PropertyValue<UIColor>) in
            view.avatarImageView.tintColor = value.value
            view.borderColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "badgeColor") { (view: UITabBarItem, value: PropertyValue<UIColor>) in
            view.badgeColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "largeTextColor") { (view: UINavigationBar, value: PropertyValue<UIColor>) in
            if #available(iOS 11.0, *) {
                view.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: value.value]
            }
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "textColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.commentLabel.textColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "butttonsColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.bordersColor = value.value
            pinpad.setColor(value.value, for: .normal)
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "backgroundColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.backgroundView.backgroundColor = value.value
            pinpad.view.backgroundColor = value.value
            pinpad.commentLabel.backgroundColor = value.value
            
            for view in pinpad.view.subviews {
                if view is UIStackView {
                    for view in view.subviews {
                        view.backgroundColor = .clear
                    }
                }
            }
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "buttonsHighlightedColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "placeholderActiveColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.placeholderActiveColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "placeholderNormalColor") { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.placeholderNormalColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "indicatorColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.indicatorColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "textColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.textColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "selectedTextColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.selectedTextColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "backgroundColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.backgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "selectedBackgroundColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.selectedBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "menuBackgroundColor") { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.menuBackgroundColor = value.value
        })
        
        self.observeThemeChange()
		
		// MARK: 3. Show login
		
		guard let router = container.resolve(Router.self) else {
			fatalError("Failed to get Router")
		}
		
		let login = router.get(scene: AdamantScene.Login.login)
		window!.rootViewController?.present(login, animated: false, completion: nil)
		
		// MARK: 4. Prepare pages
		if let tabbar = window?.rootViewController as? UITabBarController {
			let chatListRoot = router.get(scene: AdamantScene.Chats.chatList)
			let chatList = UINavigationController(rootViewController: chatListRoot)
			chatList.tabBarItem.title = String.adamantLocalized.tabItems.chats
			chatList.tabBarItem.image = #imageLiteral(resourceName: "chats_tab")
			
			let accountRoot = router.get(scene: AdamantScene.Account.account)
			let account = UINavigationController(rootViewController: accountRoot)
			account.tabBarItem.title = String.adamantLocalized.tabItems.account
			account.tabBarItem.image = #imageLiteral(resourceName: "account-tab")
			
			chatList.tabBarItem.badgeColor = UIColor.adamant.primary
			account.tabBarItem.badgeColor = UIColor.adamant.primary
			
			tabbar.setViewControllers([chatList, account], animated: false)
		}
		
		
		// MARK: 5 Reachability & Autoupdate
		repeater = RepeaterService()
		
		// Configure reachability
		if let reachability = container.resolve(ReachabilityMonitor.self) {
			reachability.start()
			
			switch reachability.connection {
			case .cellular, .wifi:
                dialogService.dissmisNoConnectionNotification()
				break
				
			case .none:
                dialogService.showNoConnectionNotification()
				repeater.pauseAll()
			}
			
			NotificationCenter.default.addObserver(forName: Notification.Name.AdamantReachabilityMonitor.reachabilityChanged, object: reachability, queue: nil) { [weak self] notification in
				guard let connection = notification.userInfo?[AdamantUserInfoKey.ReachabilityMonitor.connection] as? AdamantConnection,
					let repeater = self?.repeater else {
						return
				}
				
				switch connection {
				case .cellular, .wifi:
                    self?.dialogService.dissmisNoConnectionNotification()
					repeater.resumeAll()
					
				case .none:
                    self?.dialogService.showNoConnectionNotification()
					repeater.pauseAll()
				}
			}
		}
		
		// Register repeater services
		if let chatsProvider = container.resolve(ChatsProvider.self) {
			repeater.registerForegroundCall(label: "chatsProvider", interval: 3, queue: .global(qos: .utility), callback: chatsProvider.update)
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
		
		
		// MARK: 6. Logout reset
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantAccountService.userLoggedOut, object: nil, queue: OperationQueue.main) { [weak self] _ in
			// On logout, pop all navigators to root.
			guard let tbc = self?.window?.rootViewController as? UITabBarController, let vcs = tbc.viewControllers else {
				return
			}
			
			for case let nav as UINavigationController in vcs {
				nav.popToRootViewController(animated: false)
			}
		}
		
		// MARK: 7. Welcome messages
		NotificationCenter.default.addObserver(forName: Notification.Name.AdamantChatsProvider.initialSyncFinished, object: nil, queue: OperationQueue.main, using: handleWelcomeMessages)
		
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
		
		if let connection = container.resolve(ReachabilityMonitor.self)?.connection {
			switch connection {
			case .wifi, .cellular:
				repeater.resumeAll()
				
			case .none:
				break
			}
		} else {
			repeater.resumeAll()
		}
	}
}

// MARK: - Remote notifications
extension AppDelegate {
	private struct RegistrationPayload: Codable {
		let token: String
		
		#if DEBUG
			let provider: String = "apns-sandbox"
		#else
			let provider: String = "apns"
		#endif
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		guard let address = accountService.account?.address, let keypair = accountService.keypair else {
			print("Trying to register with no user logged")
			UIApplication.shared.unregisterForRemoteNotifications()
			return
		}
		
		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		
		// MARK: 1. Checking, if device token had not changed
		guard let securedStore = container.resolve(SecuredStore.self) else {
			fatalError("can't get secured store to get device token hash")
		}
		
		let tokenHash = token.md5()
		
		if let savedHash = securedStore.get(StoreKey.application.deviceTokenHash), tokenHash == savedHash {
			return
		} else {
			securedStore.set(tokenHash, for: StoreKey.application.deviceTokenHash)
		}
		
		// MARK: 2. Preparing message
		guard let adamantCore = container.resolve(AdamantCore.self) else {
			fatalError("Can't get AdamantCore to register device token")
		}
		
		let payload: String
		do {
			let data = try JSONEncoder().encode(RegistrationPayload(token: token))
			payload = String(data: data, encoding: String.Encoding.utf8)!
		} catch {
			dialogService.showError(withMessage: "Failed to prepare ANS signal payload", error: error)
			return
		}
		
		guard let encodedPayload = adamantCore.encodeMessage(payload, recipientPublicKey: AdamantResources.contacts.ansPublicKey, privateKey: keypair.privateKey) else {
			dialogService.showError(withMessage: "Failed to encode ANS signal. Payload: \(payload)", error: nil)
			return
		}
		
		// MARK: 3. Send signal to ANS
		guard let apiService = container.resolve(ApiService.self) else {
			fatalError("can't get api service to register device token")
		}
		
		apiService.sendMessage(senderId: address, recipientId: AdamantResources.contacts.ansAddress, keypair: keypair, message: encodedPayload.message, type: ChatType.signal, nonce: encodedPayload.nonce) { [unowned self] result in
			switch result {
			case .success:
				return
				
			case .failure(let error):
				self.notificationService?.setNotificationsMode(.disabled, completion: nil)
				self.dialogService.showRichError(error: error)
			}
		}
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		if let service = container.resolve(DialogService.self) {
			service.showError(withMessage: String.localizedStringWithFormat(String.adamantLocalized.notifications.registerRemotesError, error.localizedDescription), error: error)
		}
	}
}


// MARK: - Background Fetch
extension AppDelegate {
	func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		let container = Container()
		container.registerAdamantBackgroundFetchServices()
		
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
		
		if let welcome = AdamantContacts.adamantBountyWallet.messages["chats.welcome_message"] {
			chatProvider.fakeReceived(message: welcome.message,
									  senderId: AdamantContacts.adamantBountyWallet.name,
									  date: Date.adamantNullDate,
									  unread: unread,
									  silent: welcome.silentNotification,
									  completion: { _ in })
		}
		
		if let ico = AdamantContacts.adamantIco.messages["chats.ico_message"] {
			chatProvider.fakeReceived(message: ico.message,
									  senderId: AdamantContacts.adamantIco.name,
									  date: Date.adamantNullDate,
									  unread: unread,
									  silent: ico.silentNotification,
									  completion: { _ in })
		}
	}
}


extension AppDelegate: Themeable {
    func apply(theme: BaseTheme) {
        let name = theme.name
        print("Apply \(name) theme")
        if let theme = self.themes[theme.name] {
            Stylist.shared.addTheme(theme, name: "main")
        }
    }
}

extension UITextField {
    
    private struct UITextField_AssociatedKeys {
        static var clearButtonTint = "uitextfield_clearButtonTint"
        static var originalImage = "uitextfield_originalImage"
    }
    
    private var originalImage: UIImage? {
        get {
            if let cl = objc_getAssociatedObject(self, &UITextField_AssociatedKeys.originalImage) as? Wrapper<UIImage> {
                return cl.underlying
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &UITextField_AssociatedKeys.originalImage, Wrapper<UIImage>(newValue), .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var clearButtonTint: UIColor? {
        get {
            if let cl = objc_getAssociatedObject(self, &UITextField_AssociatedKeys.clearButtonTint) as? Wrapper<UIColor> {
                return cl.underlying
            }
            return nil
        }
        set {
            UITextField.runOnce
            objc_setAssociatedObject(self, &UITextField_AssociatedKeys.clearButtonTint, Wrapper<UIColor>(newValue), .OBJC_ASSOCIATION_RETAIN)
            applyClearButtonTint()
        }
    }
    
    private static let runOnce: Void = {
        Swizzle.for(UITextField.self, selector: #selector(UITextField.layoutSubviews), with: #selector(UITextField.uitextfield_layoutSubviews))
    }()
    
    private func applyClearButtonTint() {
        if let button = UIView.find(of: UIButton.self, in: self), let color = clearButtonTint {
            if originalImage == nil {
                originalImage = button.image(for: .normal)
            }
            button.setImage(originalImage?.tinted(with: color), for: .normal)
        }
    }
    
    @objc func uitextfield_layoutSubviews() {
        uitextfield_layoutSubviews()
        applyClearButtonTint()
    }
    
}

class Wrapper<T> {
    var underlying: T?
    
    init(_ underlying: T?) {
        self.underlying = underlying
    }
}

extension UIView {
    
    static func find<T>(of type: T.Type, in view: UIView, includeSubviews: Bool = true) -> T? where T: UIView {
        if view.isKind(of: T.self) {
            return view as? T
        }
        for subview in view.subviews {
            if subview.isKind(of: T.self) {
                return subview as? T
            } else if includeSubviews, let control = find(of: type, in: subview) {
                return control
            }
        }
        return nil
    }
    
}

extension UIImage {
    
    func tinted(with color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
}

class Swizzle {
    
    class func `for`(_ className: AnyClass, selector originalSelector: Selector, with newSelector: Selector) {
        if let method: Method = class_getInstanceMethod(className, originalSelector),
            let swizzledMethod: Method = class_getInstanceMethod(className, newSelector) {
        if (class_addMethod(className, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
            class_replaceMethod(className, newSelector, method_getImplementation(method), method_getTypeEncoding(method))
        } else {
            method_exchangeImplementations(method, swizzledMethod)
        }
        }
    }
    
}
