//
//  TransparentWindow.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import UIKit
import Combine

final class TransparentWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == hitView ? nil : hitView
    }
}
