//
//  UITextField+adamant.swift
//  Adamant
//
//  Created by Anton Boyarkin on 19/10/2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import UIKit

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
    
    func setPopupKeyboardType(_ type: UIKeyboardType) {
        guard !isMacOS else { return }
        keyboardType = type
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

// MARK: Set line break
extension UITextField {
    func setLineBreakMode() {
        if let oldStyle = self.defaultTextAttributes[.paragraphStyle, default: NSParagraphStyle()] as? NSParagraphStyle,
           let style = oldStyle.mutableCopy() as? NSMutableParagraphStyle {
            style.lineBreakMode = .byTruncatingMiddle
            self.defaultTextAttributes[.paragraphStyle] = style
        }
    }
}
