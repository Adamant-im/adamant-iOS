//
//  ThemesManager.swift
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

enum ThemesManagerError: Error {
    case failedLoadingTheme
    case redundantObservationError
}

extension StoreKey {
    struct ThemesManager {
        static let selectedTheme = "themesManager.selectedTheme"
    }
}

extension Notification.Name {
    struct ThemesManager {
        static let themeChanged = Notification.Name("adamant.themesManager.themeChanged")
        
        private init() {}
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

// MARK: - Manager
class ThemesManager {
    // MARK: Singleton
    static let shared: ThemesManager = ThemesManager()
    
    // MARK: Dependencies
    var securedStore: SecuredStore? {
        didSet {
            if let securedStore = securedStore, let id = securedStore.get(StoreKey.ThemesManager.selectedTheme), let theme = themes[id] {
                currentTheme = theme
            }
        }
    }
    
    // MARK: - Properties
    
    private var observations: Set<ObjectIdentifier> = []
    
    // MARK: - Themes
    
    /// Available themes
    let themes: [String: AdamantTheme]
    
    let defaultTheme: AdamantTheme
    
    private (set) var currentTheme: AdamantTheme
    
    func applyTheme(_ theme: AdamantTheme) {
        currentTheme = theme
        notify()
        
        securedStore?.set(currentTheme.id, for: StoreKey.ThemesManager.selectedTheme)
    }
    
    // MARK: - Init
    
    private init() {
        // MARK: Initializing themes
        let light = try! Themes.Light()
        let dark = try! Themes.Dark()
        
        self.themes = [
            light.id: light,
            dark.id: dark
        ]
        
        self.defaultTheme = light
        self.currentTheme = light
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ThemesManager.handleDynamicTypeChange(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }
    
    // MARK: - Theme changed notify
    
    private func notify() {
        NotificationCenter.default.post(name: Notification.Name.ThemesManager.themeChanged, object: self)
        
        /*
        DispatchQueue.main.async { [weak self] in
            self?.notificationCenter.post(name: ThemesManager.notificationName, object: self)
            
             NotificationCenter notifies its observers
             synchronously, so we do not need to wait:
                        #if os(iOS)
                        // HACK: apparently the only way to
                        // change the appearance of existing instances:
                        for window in UIApplication.shared.windows {
                            for view in window.subviews {
                                view.removeFromSuperview()
                                window.addSubview(view)
                            }
                        }
                        #endif
        }
        */
    }
    
    // MARK: - Managing 
    
    public func manage<U>(for themeable: U) where U: Themeable {
        let identifier = ObjectIdentifier(themeable)
        if self.observations.contains(identifier) {
            do {
                throw ThemesManagerError.redundantObservationError
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
        
        var associatedObjectKey = ObjectIdentifier(ThemesManager.self)
        objc_setAssociatedObject(
            themeable,
            &associatedObjectKey,
            disposable,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    private func observe(closure: @escaping (AdamantTheme) -> ()) -> Disposable {
        let observer = ThemeObserver { theme in
            closure(theme)
        }
        
        add(observer: observer)
        
        closure(currentTheme)
        
        // Strongly references the observer (required):
        return Disposable {
            self.remove(observer: observer)
        }
    }
    
    private func add(observer: ThemeObserver) {
        NotificationCenter.default.addObserver(forName: Notification.Name.ThemesManager.themeChanged, object: self, queue: OperationQueue.main) { [weak observer] notification in
            guard let themesManager = notification.object as? ThemesManager else {
                return
            }
            guard let strongObserver = observer else {
                return
            }
            strongObserver.handleThemeChange(on: themesManager)
        }
    }
    
    private func remove(observer: ThemeObserver) {
        NotificationCenter.default.removeObserver(observer, name: Notification.Name.ThemesManager.themeChanged, object: self)
    }
    
    @objc private func handleDynamicTypeChange(_ notification: Notification) {
        self.notify()
    }
}

// MARK: - Observer
private class ThemeObserver {
    private let closure: (AdamantTheme) -> ()
    
    init(closure: @escaping (AdamantTheme) -> ()) {
        self.closure = closure
    }
    
    func handleThemeChange(on themesManager: ThemesManager) {
        let theme = themesManager.currentTheme
        
        if Thread.isMainThread {
            closure(theme)
        } else {
            DispatchQueue.main.async {
                self.closure(theme)
            }
        }
    }
}

// MARK: - StyleProperty convinient init
private extension StyleProperty {
    init <ViewType, PropertyType>(_ styleName: AdamantThemeStyleProperty, style: @escaping (ViewType, PropertyValue<PropertyType>) -> Void) {
        self.init(name: styleName.rawValue, style: style)
    }
}

// MARK: - Register style properties
extension ThemesManager {
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
}
