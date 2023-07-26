//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 13.07.2023.
//

import Foundation
import SwiftUI

class ContextMenuOverlayViewModelMac: ObservableObject {
    let menu: AMenuViewController?
    let upperContentView: AnyView?
    let upperContentSize: CGSize
    var locationOnScreen: CGPoint
    
    @Published var isContextMenuVisible = false
    
    let topContentTransition = AnyTransition.asymmetric(
        insertion: .scale(scale: 0, anchor: .bottom),
        removal: AnyTransition.opacity.combined(
            with: .scale(scale: 0, anchor: .bottom)
        )
    )
    
    let menuTransition = AnyTransition.asymmetric(
        insertion: .scale(scale: 0, anchor: .top),
        removal: AnyTransition.opacity.combined(
            with: .scale(scale: 0, anchor: .top)
        )
    )
    
    var menuSize: CGSize {
        menu?.menuSize ?? .init(width: 250, height: 300)
    }
    
    var upperContentViewLocation: CGPoint = .zero
    var menuLocation: CGPoint = .zero
    var finalOffsetForUpperContentView: CGFloat = .zero
    
    weak var delegate: OverlayViewDelegate?
    
    // MARK: Init
    
    init(
        menu: AMenuViewController?,
        upperContentView: AnyView? = nil,
        upperContentSize: CGSize,
        locationOnScreen: CGPoint,
        delegate: OverlayViewDelegate?
    ) {
        self.menu = menu
        self.upperContentView = upperContentView
        self.upperContentSize = upperContentSize
        self.locationOnScreen = locationOnScreen
        self.isContextMenuVisible = isContextMenuVisible
        self.delegate = delegate
        
        menuLocation = calculateMenuLocation()
        upperContentViewLocation = calculateUpperContentViewLocation()
    }
    
    func dismiss() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isContextMenuVisible.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            self.delegate?.didDissmis()
        }
    }
}

private extension ContextMenuOverlayViewModelMac {
    func calculateUpperContentViewLocation() -> CGPoint {
        .init(
            x: calculateLeadingOffset(for: upperContentSize.width),
            y: calculateUpperContentTopOffset()
        )
    }
    
    func calculateMenuLocation() -> CGPoint {
        .init(
            x: calculateLeadingOffset(for: menuSize.width),
            y: calculateMenuTopOffset()
        )
    }
    
    func calculateUpperContentTopOffset() -> CGFloat {
        guard isNeedToMoveFromBottom() else {
            return locationOnScreen.y
            - upperContentSize.height
            - minContentsSpace
        }
        
        let location = UIScreen.main.bounds.height - menuSize.height - minBottomOffset
        
        return location
        - upperContentSize.height
        - minContentsSpace
    }
    
    func calculateMenuTopOffset() -> CGFloat {
        guard isNeedToMoveFromBottom() else {
            return locationOnScreen.y
        }
        
        return UIScreen.main.bounds.height - menuSize.height - minBottomOffset
    }
    
    func calculateLeadingOffset(for width: CGFloat) -> CGFloat {
        guard isNeedToMoveFromTrailing() else {
            return locationOnScreen.x
        }
        
        return locationOnScreen.x - width
    }
    
    func updateLocationIfNeeded() {
        if isNeedToMoveFromBottom() {
            locationOnScreen.y = UIScreen.main.bounds.height - menuSize.height - minBottomOffset
        }
        
        if isNeedToMoveFromTrailing() {
            locationOnScreen.x = UIScreen.main.bounds.width - minBottomOffset - upperContentSize.width
        }
    }
    
    func isNeedToMoveFromTrailing() -> Bool {
        UIScreen.main.bounds.width < locationOnScreen.x + upperContentSize.width + minBottomOffset
    }

    func isNeedToMoveFromBottom() -> Bool {
        UIScreen.main.bounds.height < locationOnScreen.y + menuSize.height + minBottomOffset
    }
}

private let animationDuration: TimeInterval = 0.2
private let minBottomOffset: CGFloat = 10
private let estimateMenuRowHeight: CGFloat = 50
private let minContentsSpace: CGFloat = 10
