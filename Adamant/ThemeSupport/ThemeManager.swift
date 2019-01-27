//
//  ThemeManager.swift
//  Adamant
//
//  Created by Anokhov Pavel on 27/01/2019.
//  Copyright © 2019 Adamant. All rights reserved.
//

import Foundation
import UIKit
import Stylist
import MyLittlePinpad
import MessageInputBar
import Parchment
import Eureka

enum ThemeManagerError: Error {
    case failedLoadingTheme
    case redundantObservationError
}



// MARK: - Manager
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
        Stylist.shared.addProperty(StyleProperty(.separatorColor) { (view: UITableView, value: PropertyValue<UIColor>) in
            view.separatorColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.placeholderColor) { (view: UITextField, value: PropertyValue<UIColor>) in
            if let placeholder = view.placeholder {
                view.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor: value.value])
            }
        })
        
        Stylist.shared.addProperty(StyleProperty(.clearButtonTintColor) { (view: UITextField, value: PropertyValue<UIColor>) in
            view.clearButtonTint = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.showDarkKeyboard) { (view: UITextField, value: PropertyValue<Bool>) in
            view.keyboardAppearance = value.value ? .dark : .light
        })
        
        Stylist.shared.addProperty(StyleProperty(.showDarkKeyboard) { (view: InputTextView, value: PropertyValue<Bool>) in
            view.keyboardAppearance = value.value ? .dark : .light
        })
        
        Stylist.shared.addProperty(StyleProperty(.highlightedBackgroundColor) { (view: RoundedButton, value: PropertyValue<UIColor>) in
            view.highlightedBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.normalBackgroundColor) { (view: RoundedButton, value: PropertyValue<UIColor>) in
            view.normalBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.avatarTintColor) { (view: ChatTableViewCell, value: PropertyValue<UIColor>) in
            view.avatarImageView.tintColor = value.value
            view.borderColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.badgeColor) { (view: UITabBarItem, value: PropertyValue<UIColor>) in
            view.badgeColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.largeTextColor) { (view: UINavigationBar, value: PropertyValue<UIColor>) in
            if #available(iOS 11.0, *) {
                view.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: value.value]
            }
        })
        
        Stylist.shared.addProperty(StyleProperty(.textColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.commentLabel.textColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.butttonsColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.bordersColor = value.value
            pinpad.setColor(value.value, for: .normal)
        })
        
        Stylist.shared.addProperty(StyleProperty(.backgroundColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
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
        
        Stylist.shared.addProperty(StyleProperty(.buttonsHighlightedColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
        })
        
        Stylist.shared.addProperty(StyleProperty(.placeholderActiveColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.placeholderActiveColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.placeholderNormalColor) { (pinpad: PinpadViewController, value: PropertyValue<UIColor>) in
            pinpad.placeholderNormalColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.indicatorColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.indicatorColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.textColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.textColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.selectedTextColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.selectedTextColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.backgroundColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.backgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.selectedBackgroundColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.selectedBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.menuBackgroundColor) { (view: PagingViewController<WalletPagingItem>, value: PropertyValue<UIColor>) in
            view.menuBackgroundColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.barTintColor) { (view: UIToolbar, value: PropertyValue<UIColor>) in
            view.barTintColor = value.value
        })
        
        Stylist.shared.addProperty(StyleProperty(.isDarkMode) { (view: UISearchBar, value: PropertyValue<Bool>) in
            view.barStyle = value.value ? .black : .default
        })
        
        Stylist.shared.addProperty(StyleProperty(.textColor) { (view: PickerCell<URLScheme>, value: PropertyValue<UIColor>) in
            view.pickerTextAttributes = [NSAttributedString.Key.foregroundColor: value.value]
        })
        
        Stylist.shared.addProperty(StyleProperty(.selectedBackgroundColor) { (view: UITableViewCell, value: PropertyValue<UIColor>) in
            let selectedBackgroundView = UIView()
            selectedBackgroundView.backgroundColor = value.value
            view.selectedBackgroundView = selectedBackgroundView
        })
    }
    
    static func currentTheme() -> AdamantTheme {
        let storedTheme = UserDefaults.standard.integer(forKey: SelectedThemeKey)
        
//        if let theme = AdamantTheme(rawValue: storedTheme) {
//            return theme
//        } else {
            return .default
//        }
    }
    
    static func applyTheme(theme: AdamantTheme) {
//        UserDefaults.standard.set(theme.rawValue, forKey: SelectedThemeKey)
//        UserDefaults.standard.synchronize()
        
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
            do {
                throw ThemeManagerError.redundantObservationError
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
    
    public func observe(closure: @escaping (ThemeProtocol) -> ()) -> Disposable {
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

// MARK: - Observer
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

// MARK: - Disposable
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


// MARK: - StyleProperty convinient init
private extension StyleProperty {
    init <ViewType, PropertyType>(_ styleName: AdamantThemeStyleProperty, style: @escaping (ViewType, PropertyValue<PropertyType>) -> Void) {
        self.init(name: styleName.rawValue, style: style)
    }
}
