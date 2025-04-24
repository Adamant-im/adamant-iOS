//
//  ChatMenuManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 30.05.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import AdvancedContextMenuKit
import CommonKit
import SwiftUI
import UIKit

@MainActor
protocol ChatMenuManagerDelegate: AnyObject {
    func getCopyView() -> UIView?
    func presentMenu(
        copyView: UIView,
        size: CGSize,
        location: CGPoint,
        tapLocation: CGPoint,
        getPositionOnScreen: @escaping () -> CGPoint
    )
    var isFailedMessage: Bool { get }
    func showFailedMenu()
}

@MainActor
final class ChatMenuManager: NSObject {
    weak var delegate: ChatMenuManagerDelegate?

    // MARK: Init

    init(delegate: ChatMenuManagerDelegate?) {
        self.delegate = delegate
    }

    func setup(for contentView: UIView) {
        guard !isMacOS else {
            let interaction = UIContextMenuInteraction(delegate: self)
            contentView.addInteraction(interaction)
            return
        }
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
}

extension ChatMenuManager: UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        if let delegate = delegate, delegate.isFailedMessage {
            delegate.showFailedMenu()
            return nil
        }
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
