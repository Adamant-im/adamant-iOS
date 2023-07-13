//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 13.07.2023.
//

import Foundation
import SwiftUI

class ContextMenuOverlayViewModelMac: ObservableObject {
    let menu: UIMenu
    let upperContentView: AnyView?
    let upperContentSize: CGSize
    var locationOnScreen: CGPoint
    
    @Published var menuHeight: CGFloat = .zero
    @Published var isContextMenuVisible = false
    
    let transition = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.9, anchor: .center),
        removal: .identity
    )
    
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
    
    weak var delegate: OverlayViewDelegate?
    
    private let minBottomOffset: CGFloat = 100

    // MARK: Init
    
    init(
        menu: UIMenu,
        upperContentView: AnyView? = nil,
        upperContentSize: CGSize,
        locationOnScreen: CGPoint,
        menuHeight: CGFloat = .zero,
        delegate: OverlayViewDelegate?
    ) {
        self.menu = menu
        self.upperContentView = upperContentView
        self.upperContentSize = upperContentSize
        self.locationOnScreen = locationOnScreen
        self.menuHeight = menuHeight
        self.isContextMenuVisible = isContextMenuVisible
        self.delegate = delegate
        
        updateLocationIfNeeded()
    }
    
    func updateLocationIfNeeded() {
        if isNeedToMoveFromBottom() {
            locationOnScreen.y = UIScreen.main.bounds.height - menuHeight - minBottomOffset
        }
        
        if isNeedToMoveFromTrailing() {
            locationOnScreen.x = UIScreen.main.bounds.width - minBottomOffset - upperContentSize.width
        }
    }
    
    func isNeedToMoveFromTrailing() -> Bool {
        UIScreen.main.bounds.width < locationOnScreen.x + upperContentSize.width + minBottomOffset
    }

    func isNeedToMoveFromBottom() -> Bool {
        UIScreen.main.bounds.height < locationOnScreen.y + menuHeight + minBottomOffset
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

private let animationDuration: TimeInterval = 0.2
