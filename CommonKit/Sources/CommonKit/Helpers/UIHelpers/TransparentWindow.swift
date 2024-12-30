//
//  TransparentWindow.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit

/// https://forums.developer.apple.com/forums/thread/762292
public final class TransparentWindow: UIWindow {
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        /// on iOS 18 `rootViewController.view` greedily captures taps, even when it's hierarchy contains no interactive views
        /// if it's hierarchy _does_ contain interactive elements, it returns *itself* when calling `.hitTest`
        /// this is problematic because it's frame likely fills the whole screen, causing everything behind it to become non-interactive
        /// to fix this, we have to perform hit testing on it's _subviews_
        /// looping through it's subviews while performing `.hitTest` won't work though, as `hitTest` doesn't return the depth at which it found a hit
        /// as we are interested in the hit at the deepest depth, we have to reimplement it
        /// once we have obtained the deepest hit, just overriding `.hitTest` and returning the deepest view doesn't work, as  gesture recognizers are registered on `rootViewController.view`, not the hit view
        /// we therefor still return the default hit test result, but only if the tap was detected within the bounds of the _deepest view_
        if #available(iOS 18, *) {
            guard let view = rootViewController?.view else { return false }
            
            let hit = Self._hitTest(
                point,
                with: event,
                /// happens when e.g. `UIAlertController` is presented
                /// not advisable when added subviews are potentially non-interactive, as `rootViewController?.view` itself is part of `self.subviews`, and therefor participates in hit testing
                view: subviews.count > 1 ? self : view
            )
            
            return hit != nil
        } else {
            return super.point(inside: point, with: event)
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 18, *) {
            return super.hitTest(point, with: event)
        } else {
            guard let hit = super.hitTest(point, with: event) else { return .none }
            return rootViewController?.view == hit ? .none : hit
        }
    }
}

private extension TransparentWindow {
    static func _hitTest(
        _ point: CGPoint,
        with event: UIEvent?,
        view: UIView,
        depth: Int = .zero
    ) -> (view: UIView, depth: Int)? {
        var deepest: (view: UIView, depth: Int)?
        
        /// views are ordered back-to-front
        for subview in view.subviews.reversed() {
            let converted = view.convert(point, to: subview)
            
            guard
                subview.isUserInteractionEnabled,
                !subview.isHidden,
                subview.alpha > .zero,
                subview.point(inside: converted, with: event)
            else { continue }
            
            let result = if let hit = _hitTest(
                converted,
                with: event,
                view: subview,
                depth: depth + 1
            ) {
                hit
            } else {
                (view: subview, depth: depth)
            }
            
            if case .none = deepest {
                deepest = result
            } else if let current = deepest, result.depth > current.depth {
                deepest = result
            }
        }
        
        return deepest
    }
}
