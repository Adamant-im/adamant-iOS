//
//  File.swift
//
//
//  Created by Stanislav Jelezoglo on 13.07.2023.
//

import CommonKit
import Foundation
import SwiftUI

@MainActor
final class ContextMenuOverlayViewModelMac: ObservableObject {
    let menu: AMenuViewController?
    let contentView: UIView
    let contentViewSize: CGSize
    let upperContentView: AnyView?
    let upperContentSize: CGSize
    var locationOnScreen: CGPoint
    var contentLocation: CGPoint
    let animationDuration: TimeInterval

    @Published var additionalMenuVisible = false

    var menuSize: CGSize {
        menu?.menuSize ?? .init(width: 250, height: 300)
    }

    var upperContentViewLocation: CGPoint = .zero
    var menuLocation: CGPoint = .zero
    var finalOffsetForUpperContentView: CGFloat = .zero

    weak var delegate: OverlayViewDelegate?

    private var screenSize: CGSize = UIScreen.main.bounds.size

    // MARK: Init

    init(
        contentView: UIView,
        contentViewSize: CGSize,
        menu: AMenuViewController?,
        upperContentView: AnyView? = nil,
        upperContentSize: CGSize,
        locationOnScreen: CGPoint,
        contentLocation: CGPoint,
        animationDuration: TimeInterval,
        delegate: OverlayViewDelegate?
    ) {
        self.contentView = contentView
        self.contentViewSize = contentViewSize
        self.menu = menu
        self.upperContentView = upperContentView
        self.upperContentSize = upperContentSize
        self.locationOnScreen = locationOnScreen
        self.delegate = delegate
        self.contentLocation = contentLocation
        self.animationDuration = animationDuration

        menuLocation = calculateMenuLocation()
        upperContentViewLocation = calculateUpperContentViewLocation()
    }

    @MainActor func dismiss() async {
        await animate(duration: animationDuration) {
            self.additionalMenuVisible.toggle()
        }

        delegate?.didDissmis()
    }

    func updateLocations(geometry: GeometryProxy) -> EmptyView {
        screenSize = geometry.size
        menuLocation = calculateMenuLocation()
        upperContentViewLocation = calculateUpperContentViewLocation()
        return EmptyView()
    }
}

extension ContextMenuOverlayViewModelMac {
    fileprivate func calculateUpperContentViewLocation() -> CGPoint {
        .init(
            x: calculateLeadingOffset(for: upperContentSize.width),
            y: calculateUpperContentTopOffset()
        )
    }

    fileprivate func calculateMenuLocation() -> CGPoint {
        .init(
            x: calculateLeadingOffset(for: menuSize.width),
            y: calculateMenuTopOffset()
        )
    }

    fileprivate func calculateUpperContentTopOffset() -> CGFloat {
        guard isNeedToMoveFromBottom() else {
            return locationOnScreen.y
                - upperContentSize.height
                - minContentsSpace
        }

        let location = screenSize.height - menuSize.height - minBottomOffset

        return location
            - upperContentSize.height
            - minContentsSpace
    }

    fileprivate func calculateMenuTopOffset() -> CGFloat {
        guard isNeedToMoveFromBottom() else {
            return locationOnScreen.y
        }

        return screenSize.height - menuSize.height - minBottomOffset
    }

    fileprivate func calculateLeadingOffset(for width: CGFloat) -> CGFloat {
        guard isNeedToMoveFromTrailing() else {
            return locationOnScreen.x
        }

        return locationOnScreen.x - width
    }

    fileprivate func isNeedToMoveFromTrailing() -> Bool {
        screenSize.width < locationOnScreen.x + upperContentSize.width + minBottomOffset
    }

    fileprivate func isNeedToMoveFromBottom() -> Bool {
        screenSize.height < locationOnScreen.y + menuSize.height + minBottomOffset
    }
}

private let animationDuration: TimeInterval = 0.2
private let minBottomOffset: CGFloat = 10
private let estimateMenuRowHeight: CGFloat = 50
private let minContentsSpace: CGFloat = 10
