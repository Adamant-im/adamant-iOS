//
//  ContextMenuOverlayViewModel.swift
//  
//
//  Created by Stanislav Jelezoglo on 07.07.2023.
//

import SwiftUI

class ContextMenuOverlayViewModel: ObservableObject {
    let contentView: UIView
    let topYOffset: CGFloat
    let newContentHeight: CGFloat
    let oldContentHeight: CGFloat
    let newContentWidth: CGFloat
    let menu: UIMenu
    let menuAlignment: Alignment
    let upperContentView: AnyView?
    let upperContentSize: CGSize
    let superViewXOffset: CGFloat
    
    @Published var menuHeight: CGFloat = .zero
    @Published var isContextMenuVisible = false
    
    var topOfContentViewOffset: CGFloat {
        topYOffset// - (newContentHeight - oldContentHeight) / 2
    }
    
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
    
    private let minBottomOffset: CGFloat = 50
    private let minContentsSpace: CGFloat = 10
    
    init(contentView: UIView, topYOffset: CGFloat, newContentHeight: CGFloat, oldContentHeight: CGFloat, newContentWidth: CGFloat, menu: UIMenu, menuAlignment: Alignment, upperContentView: AnyView?, upperContentSize: CGSize, superViewXOffset: CGFloat) {
        self.contentView = contentView
        self.topYOffset = topYOffset
        self.newContentHeight = newContentHeight
        self.oldContentHeight = oldContentHeight
        self.newContentWidth = newContentWidth
        self.menu = menu
        self.menuAlignment = menuAlignment
        self.upperContentView = upperContentView
        self.upperContentSize = upperContentSize
        self.superViewXOffset = superViewXOffset
    }
    
    func isNeedToMoveFromTop() -> Bool {
        topOfContentViewOffset - minContentsSpace - upperContentSize.height < minBottomOffset
    }
    
    func getOffsetToMoveFromTop() -> CGFloat {
        minContentsSpace
        + upperContentSize.height
            + minBottomOffset
    }
    
    func isNeedToMoveFromBottom(for bottomPosition: CGFloat) -> Bool {
        UIScreen.main.bounds.height - bottomPosition < (menuHeight + minBottomOffset)
    }
    
    func getOffsetToMoveFromBottom() -> CGFloat {
        UIScreen.main.bounds.height
            - menuHeight
            - newContentHeight
            - minBottomOffset
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
