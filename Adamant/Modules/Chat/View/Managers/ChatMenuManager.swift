//
//  ChatMenuManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import SwiftUI
import AdvancedContextMenuKit
import CommonKit

protocol ChatMenuManagerDelegate: AnyObject {
    func getCopyView() -> UIView?
    func presentMenu(
        copyView: UIView,
        size: CGSize,
        location: CGPoint,
        tapLocation: CGPoint,
        getPositionOnScreen: @escaping () -> CGPoint
    )
}

@MainActor
final class ChatMenuManager: NSObject {
    weak var delegate: ChatMenuManagerDelegate?
    
    var isiOSAppOnMac: Bool = {
#if targetEnvironment(macCatalyst)
        return true
#else
        if #available(iOS 14.0, *) {
            return ProcessInfo.processInfo.isiOSAppOnMac
        } else {
            return false
        }
#endif
    }()
    
    // MARK: Init
    
    init(delegate: ChatMenuManagerDelegate?) {
        self.delegate = delegate
    }
    
    func setup(for contentView: UIView) {
        guard !isiOSAppOnMac else {
            let interaction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(interaction)
            return
        }
        
        let longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.17
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    func presentMenuProgrammatically(for contentView: UIView) {
        let locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
        
        let size = contentView.frame.size
        
        let copyView = delegate?.getCopyView() ?? contentView
        
        let getPositionOnScreen: () -> CGPoint = { [weak contentView] in
            contentView?.convert(CGPoint.zero, to: nil) ?? .zero
        }
        
        delegate?.presentMenu(
            copyView: copyView,
            size: size,
            location: locationOnScreen,
            tapLocation: .init(
                x: locationOnScreen.x + size.width / 2,
                y: locationOnScreen.y + size.height / 2
            ),
            getPositionOnScreen: getPositionOnScreen
        )
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard !isiOSAppOnMac else { return }
        
        guard gesture.state == .began,
              let contentView = gesture.view
        else { return }
        
        let locationOnScreen = contentView.convert(CGPoint.zero, to: nil)
        
        let size = contentView.frame.size
        
        let copyView = delegate?.getCopyView() ?? contentView
        
        let getPositionOnScreen: () -> CGPoint = {
            contentView.convert(CGPoint.zero, to: nil)
        }
        
        delegate?.presentMenu(
            copyView: copyView,
            size: size,
            location: locationOnScreen,
            tapLocation: .zero,
            getPositionOnScreen: getPositionOnScreen
        )
    }
}

extension ChatMenuManager: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        presentMacOverlay(interaction, configurationForMenuAtLocation: location)
        return nil
    }
    
    func presentMacOverlay(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) {
        guard let contentView = interaction.view
        else { return }
        
        let contentLocation = contentView.convert(CGPoint.zero, to: nil)
        let tapLocation: CGPoint = .init(
            x: contentLocation.x + location.x,
            y: contentLocation.y + location.y
        )
        let size = contentView.frame.size
        
        let copyView = delegate?.getCopyView() ?? contentView
        
        let getPositionOnScreen: () -> CGPoint = {
            contentView.convert(CGPoint.zero, to: nil)
        }
        
        delegate?.presentMenu(
            copyView: copyView,
            size: size,
            location: contentLocation,
            tapLocation: tapLocation,
            getPositionOnScreen: getPositionOnScreen
        )
    }
}
