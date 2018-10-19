//
//  ThemeService.swift
//  Adamant
//
//  Created by Anton Boyarkin on 06/09/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import UIKit

enum ADMTheme: Int, Codable {
    case light = 0
    case dark = 1

    static let `default`: ADMTheme = .light

    var theme: BaseTheme {
        switch self {
        case .light: return LightTheme()
        case .dark: return DarkTheme()
            
//        default: return Theme.default.theme
        }
    }
    
    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

public protocol BaseTheme {
    var name: String { get }
    
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

struct LightTheme: BaseTheme {
    let name = "light"
    
    // MARK: Global colors

    /// Main dark gray, ~70% gray
    let primary = UIColor(hex: "#474a5f")

    /// Secondary color, ~50% gray
    let secondary = UIColor(hex: "#9497a3")
    
    let activeColor = UIColor(hex: "#179cec")
    
    let successColor = UIColor(hex: "#50fa7b")
    
    let alertColor = UIColor(hex: "#faa05a")

    /// Chat icons color, ~40% gray
    let chatIcons = UIColor(red: 0.62, green: 0.62, blue: 0.62, alpha: 1)

    /// Table row icons color, ~45% gray
    let tableRowIcons = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)

    let background = UIColor(hex: "#ffffff")
    let secondaryBackground = UIColor.groupTableViewBackground

    // MARK: Chat colors

    /// User chat bubble background, ~4% gray
    let chatRecipientBackground = UIColor(hex: "#ffffff")//UIColor(red: 0.965, green: 0.973, blue: 0.981, alpha: 1)
    let pendingChatBackground = UIColor(hex: "#ffffff")//UIColor(white: 0.98, alpha: 1.0)
    let failChatBackground = UIColor(hex: "#ffffff")//UIColor(white: 0.8, alpha: 1.0)
    
    /// Partner chat bubble background, ~8% gray
    let chatSenderBackground = UIColor(hex: "#ffffff")//UIColor(red: 0.925, green: 0.925, blue: 0.925, alpha: 1)


    // MARK: Pinpad
    /// Pinpad highligh button background, 12% gray
    let pinpadHighlightButton = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1)


    // MARK: Transfers
    /// Income transfer icon background, light green
    let transferIncomeIconBackground = UIColor(red: 0.7, green: 0.93, blue: 0.55, alpha: 1)

    // Outcome transfer icon background, light red
    let transferOutcomeIconBackground = UIColor(red: 0.94, green: 0.52, blue: 0.53, alpha: 1)
    
    let statusBar = UIStatusBarStyle.default
}

struct DarkTheme: BaseTheme {
    let name = "dark"
    
    let primary = UIColor(hex: "#D5DDE5")

    let secondary = UIColor(hex: "#9497a3")
    
    let activeColor = UIColor(hex: "#179cec")
    
    let successColor = UIColor(hex: "#50fa7b")
    
    let alertColor = UIColor(hex: "#faa05a")

    let chatIcons = UIColor(hex: "")

    let tableRowIcons = UIColor(hex: "")

    let background = UIColor(hex: "#0D0905")
    var secondaryBackground = UIColor(hex: "#474a5f")

    let chatRecipientBackground = UIColor(hex: "#53566E")

    let pendingChatBackground = UIColor(hex: "#474a5f")

    let failChatBackground = UIColor(hex: "#474a5f")

    let chatSenderBackground = UIColor(hex: "#474a5f")

    let pinpadHighlightButton = UIColor(hex: "")

    let transferIncomeIconBackground = UIColor(hex: "")

    let transferOutcomeIconBackground = UIColor(hex: "")

    let statusBar = UIStatusBarStyle.lightContent
    
}

public class ThemeManager {
    
    public static let `default`: ThemeManager = .init()
    
    static let SelectedThemeKey = "SelectedTheme"
    
    // Notification used for broadcasting theme changes
    private static let notificationName = Notification.Name("ThemeChangedNotification")
    
    // NotificationCenter used for broadcasting theme changes
    private var notificationCenter: NotificationCenter = .init()
    
    private var observations: Set<ObjectIdentifier> = []
    
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
    
    public var theme: BaseTheme? {
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
        closure: @escaping (BaseTheme) -> ()
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
    func apply(theme: BaseTheme)
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
    private let closure: (BaseTheme) -> ()
    
    internal init(closure: @escaping (BaseTheme) -> ()) {
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
