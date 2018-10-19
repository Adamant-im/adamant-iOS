//
//  ThemeService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Stylist
import MyLittlePinpad
import Parchment
import MessageInputBar
import Eureka

enum ADMTheme: Int, Codable {
    case light = 0
    case dark = 1

    static let `default`: ADMTheme = .light

    var theme: ThemeProtocol {
        switch self {
        case .light: return LightTheme()
        case .dark: return DarkTheme()
            
//        default: return Theme.default.theme
        }
    }
    
    var title: String {
        switch self {
        case .light: return NSLocalizedString("AccountTab.Row.Theme.Light", comment: "Account tab: 'Theme' row value 'Light'")
        case .dark: return NSLocalizedString("AccountTab.Row.Theme.Dark", comment: "Account tab: 'Theme' row value 'Dark'")
        }
    }
}

public protocol ThemeProtocol {
    var name: String { get }
    var theme: Theme? { get }
    
    // MARK: Global colors

    /// Main color
    var primary: UIColor { get }

    /// Secondary color
    var secondary: UIColor { get }
    
    /// Success Color
    var successColor: UIColor { get }
    
    /// Active Color
    var activeColor: UIColor { get }
    
    /// Alert Color
    var alertColor: UIColor { get }

    /// Chat icons color
    var chatIcons: UIColor { get }

    /// Table row icons color
    var tableRowIcons: UIColor { get }

    var background: UIColor { get }
    var secondaryBackground: UIColor { get }

    // MARK: Chat colors

    /// User chat bubble background
    var chatRecipientBackground: UIColor { get }
    var pendingChatBackground: UIColor { get }
    var failChatBackground: UIColor { get }

    /// Partner chat bubble background
    var chatSenderBackground: UIColor { get }


    // MARK: Pinpad
    /// Pinpad highligh button background
    var pinpadHighlightButton: UIColor { get }


    // MARK: Transfers
    /// Income transfer icon background
    var transferIncomeIconBackground: UIColor { get }

    // Outcome transfer icon background
    var transferOutcomeIconBackground: UIColor { get }
    
    // Status bar
    var statusBar : UIStatusBarStyle { get }
}

class LightTheme:BaseTheme, ThemeProtocol {
    let name = "light"
    
    // MARK: Global colors

    var primary: UIColor {
        return getColor("firstColor")
    }
    
    var secondary: UIColor {
        return getColor("secondaryColor")
    }
    
    var activeColor: UIColor {
        return getColor("activeColor")
    }
    
    var successColor: UIColor {
        return getColor("successColor")
    }
    
    var alertColor: UIColor {
        return getColor("alertColor")
    }

    var chatIcons: UIColor {
        return getColor("firstColor")
    }
    
    var tableRowIcons: UIColor {
        return getColor("firstColor")
    }
    
    var background: UIColor {
        return getColor("backgroundColor")
    }
    
    var secondaryBackground: UIColor {
        return getColor("backgroundColor")
    }
    
    var chatRecipientBackground: UIColor {
        return getColor("backgroundColor")
    }
    
    var pendingChatBackground: UIColor {
        return getColor("backgroundColor")
    }
    
    var failChatBackground: UIColor {
        return getColor("backgroundColor")
    }
    
    var chatSenderBackground: UIColor {
        return getColor("backgroundColor")
    }
    
    var pinpadHighlightButton: UIColor {
        return getColor("backgroundColor")
    }
    
    var transferIncomeIconBackground: UIColor {
        return getColor("successColor")
    }
    
    var transferOutcomeIconBackground: UIColor {
        return getColor("alertColor")
    }
    
    let statusBar = UIStatusBarStyle.default
    
    init() {
        super.init(fileName: "ThemeLight")
    }
}

class DarkTheme:BaseTheme, ThemeProtocol {
    let name = "dark"
    
    var primary: UIColor {
        return getColor("firstColor")
    }

    var secondary: UIColor {
        return getColor("secondaryColor")
    }
    
    var activeColor: UIColor {
        return getColor("activeColor")
    }
    
    var successColor: UIColor {
        return getColor("successColor")
    }
    
    var alertColor: UIColor {
        return getColor("alertColor")
    }

    var chatIcons: UIColor {
        return getColor("firstColor")
    }

    var tableRowIcons: UIColor {
        return getColor("firstColor")
    }

    var background: UIColor {
        return getColor("backgroundColor")
    }
    
    var secondaryBackground: UIColor {
        return getColor("thirdColor")
    }

    var chatRecipientBackground: UIColor {
        return getColor("thirdColor")
    }

    var pendingChatBackground: UIColor {
        return getColor("thirdColor")
    }

    var failChatBackground: UIColor {
        return getColor("thirdColor")
    }

    var chatSenderBackground: UIColor {
        return getColor("thirdColor")
    }

    var pinpadHighlightButton: UIColor {
        return getColor("thirdColor")
    }

    var transferIncomeIconBackground: UIColor {
        return getColor("successColor")
    }

    var transferOutcomeIconBackground: UIColor {
        return getColor("alertColor")
    }

    let statusBar = UIStatusBarStyle.lightContent
    
    
    init() {
        super.init(fileName: "ThemeDark")
    }
}

class BaseTheme {
    internal var theme: Theme?
    
    internal init(fileName: String) {
        if let theme = ThemeManager.themes[fileName] {
            print("Loading cached theme: \(fileName)")
            self.theme = theme
        } else if let path = Bundle.main.path(forResource: fileName, ofType: "yaml") {
            print("Strat loading theme: \(fileName)")
            do {
                let theme = try Theme(path: path)
                self.theme = theme
                ThemeManager.themes[fileName] = theme
            } catch {
                print("Can't parse theme: \(fileName)")
                print("\(error)")
            }
        } else {
            print("Can't load theme: \(fileName)")
        }
    }
    
    internal func getColor(_ name: String) -> UIColor {
        if let theme = self.theme {
            if let colorHex = theme.variables[name] as? String {
                return UIColor(hex: colorHex)
            } else {
                print("No color for: \(name) in: \(self)")
                return UIColor.red
            }
        } else {
            print("No theme in: \(self)")
            return UIColor.red
        }
    }
}

public class ThemeManager {
    
    public static let `default`: ThemeManager = .init()
    
    static let SelectedThemeKey = "SelectedTheme"
    
    // Notification used for broadcasting theme changes
    private static let notificationName = Notification.Name("ThemeChangedNotification")
    
    // NotificationCenter used for broadcasting theme changes
    private var notificationCenter: NotificationCenter = .init()
    
    private var observations: Set<ObjectIdentifier> = []
    
    public static var themes: [String: Theme] = [:]
    
    public init() {
        self.theme = ThemeManager.currentTheme().theme
        
        #if os(iOS)
        if #available(iOS 7, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(ThemeManager.handleDynamicTypeChange(_:)),
                name: UIContentSizeCategory.didChangeNotification,
                object: nil
            )
        }
        #endif
    }
    
    static func addCustomStyleProperties() {
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
        
        Stylist.shared.addProperty(StyleProperty(name: "showDarkKeyboard") { (view: InputTextView, value: PropertyValue<Bool>) in
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
        
        Stylist.shared.addProperty(StyleProperty(name: "barTintColor") { (view: UIToolbar, value: PropertyValue<UIColor>) in
            view.barTintColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "isDarkMode") { (view: UISearchBar, value: PropertyValue<Bool>) in
            view.barStyle = value.value ? .black : .default
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "textColor") { (view: PickerCell<URLScheme>, value: PropertyValue<UIColor>) in
            view.pickerTextAttributes = [NSAttributedString.Key.foregroundColor: value.value]
        })
        
        Stylist.shared.addProperty(StyleProperty(name: "selectedBackgroundColor") { (view: UITableViewCell, value: PropertyValue<UIColor>) in
            if view.selectedBackgroundView == nil {
                view.selectedBackgroundView = UIView()
            }
            view.selectedBackgroundView?.backgroundColor = value.value
        })
    }

    static func currentTheme() -> ADMTheme {
        let storedTheme = UserDefaults.standard.integer(forKey: SelectedThemeKey)

        if let theme = ADMTheme(rawValue: storedTheme) {
            return theme
        } else {
            return .default
        }
    }

    static func applyTheme(theme: ADMTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: SelectedThemeKey)
        UserDefaults.standard.synchronize()
        
        ThemeManager.default.theme = theme.theme
    }
    
    public var theme: ThemeProtocol? {
        didSet {
            self.notify()
        }
    }
    
    public func manage<U>(for themeable: U) where U: Themeable {
        let identifier = ObjectIdentifier(themeable)
        if self.observations.contains(identifier) {
            typealias ErrorType = RedundantObservationError
            let errorName = String(describing: ErrorType.self)
            let description = String(describing: themeable)
            print("\(self): Detected redundant observation of \(description).")
            print("Info: Use a \"Swift Error Breakpoint\" on type \"\(errorName)\" to catch.")
            do {
                throw ErrorType()
            } catch {
                // intentionally left blank
            }
        }
        self.observations.insert(identifier)
        
        let disposable = self.observe { [weak themeable] theme in
            guard let strongThemeable = themeable else {
                return
            }
            strongThemeable.apply(theme: theme)
        }
        
        var associatedObjectKey = ObjectIdentifier(ThemeManager.self)
        objc_setAssociatedObject(
            themeable,
            &associatedObjectKey,
            disposable,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    public func observe(
        closure: @escaping (ThemeProtocol) -> ()
        ) -> Disposable
    {
        let observer = ThemeObserver { theme in
            closure(theme)
        }
        
        self.add(observer: observer)
        
        if let theme = self.theme {
            closure(theme)
        }
        
        // Strongly references the observer (required):
        return Disposable { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.remove(observer: observer)
        }
    }
    
    private func add(observer: ThemeObserver) {
        self.notificationCenter.addObserver(
            forName: ThemeManager.notificationName,
            object: self,
            queue: OperationQueue.main
        ) { [weak observer] notification in
            guard let themeManager = notification.object as? ThemeManager else {
                return
            }
            guard let strongObserver = observer else {
                return
            }
            strongObserver.handleThemeChange(on: themeManager)
        }
    }
    
    private func remove(observer: ThemeObserver) {
        self.notificationCenter.removeObserver(
            observer,
            name: ThemeManager.notificationName,
            object: self
        )
    }
    
    @objc private func handleDynamicTypeChange(_ notification: Notification) {
        self.notify()
    }
    
    private func notify() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.notificationCenter.post(
                name: ThemeManager.notificationName,
                object: strongSelf
            )
            
            // NotificationCenter notifies its observers
            // synchronously, so we do not need to wait:
//            #if os(iOS)
//            // HACK: apparently the only way to
//            // change the appearance of existing instances:
//            for window in UIApplication.shared.windows {
//                for view in window.subviews {
//                    view.removeFromSuperview()
//                    window.addSubview(view)
//                }
//            }
//            #endif
        }
    }
}

public protocol Themeable: class {
    func apply(theme: ThemeProtocol)
}

extension Themeable {
    public func observeThemeChange()
    {
        ThemeManager.default.manage(for: self)
    }
}

internal struct InvalidThemeError: Error {
    // intentionally left blank
}

internal struct RedundantObservationError: Error {
    // intentionally left blank
}

internal class ThemeObserver {
    private let closure: (ThemeProtocol) -> ()
    
    internal init(closure: @escaping (ThemeProtocol) -> ()) {
        self.closure = closure
    }
    
    internal func handleThemeChange(on themeManager: ThemeManager) {
        assert(Thread.isMainThread)
        
        guard let theme = ThemeManager.default.theme else {
            var themeManager = themeManager
            Swift.withUnsafePointer(to: &themeManager) {
                NSLog("No theme found for theme manager \($0)")
            }
            return
        }
//        themeManager.animated(duration: themeManager.animationDuration) {
            self.closure(theme)
//        }
    }
}

/// Disposable pattern
public class Disposable {
    private let disposal: () -> ()
    
    init(disposal: @escaping () -> ()) {
        self.disposal = disposal
    }
    
    deinit {
        self.disposal()
    }
}
