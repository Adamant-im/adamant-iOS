//
//  ContextMenuOverlayViewModel.swift
//  
//
//  Created by Stanislav Jelezoglo on 07.07.2023.
//

import SwiftUI

class ContextMenuOverlayViewModel: ObservableObject {
    let contentView: UIView
    let contentViewSize: CGSize
    let locationOnScreen: CGPoint
    let menu: AMenuViewController?
    let upperContentView: AnyView?
    let upperContentSize: CGSize
    
    var upperContentViewLocation: CGPoint = .zero
    var contentViewLocation: CGPoint = .zero
    var menuLocation: CGPoint = .zero
        
    var startOffsetForContentView: CGFloat {
        locationOnScreen.y
    }
    
    var startOffsetForUpperContentView: CGFloat {
        locationOnScreen.y - (upperContentSize.height + minContentsSpace)
    }
    
    var menuSize: CGSize {
        menu?.menuSize ?? .init(width: 250, height: 300)
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
    
    @Published var isContextMenuVisible = false
    @Published var shouldScroll: Bool = false
    
    init(
        contentView: UIView,
        contentViewSize: CGSize,
        locationOnScreen: CGPoint,
        menu: AMenuViewController?,
        upperContentView: AnyView?,
        upperContentSize: CGSize
    ) {
        self.contentView = contentView
        self.contentViewSize = contentViewSize
        self.locationOnScreen = locationOnScreen
        self.menu = menu
        self.upperContentView = upperContentView
        self.upperContentSize = upperContentSize
        
        contentViewLocation = calculateContentViewLocation()
        menuLocation = calculateMenuLocation()
        upperContentViewLocation = calculateUpperContentViewLocation()
        shouldScroll = isShoudScroll()
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

private extension ContextMenuOverlayViewModel {
    func calculateContentViewLocation() -> CGPoint {
        .init(
            x: locationOnScreen.x,
            y: calculateOffsetForContentView()
        )
    }
    
    func calculateUpperContentViewLocation() -> CGPoint {
        .init(
            x: isNeedToMoveFromTrailing()
            ? calculateLeadingOffset(for: upperContentSize.width)
            : locationOnScreen.x,
            y: calculateOffsetForUpperContentView()
        )
    }
    
    func calculateMenuLocation() -> CGPoint {
        .init(
            x: isNeedToMoveFromTrailing()
            ? calculateLeadingOffset(for: menuSize.width)
            : locationOnScreen.x,
            y: minContentsSpace
        )
    }
    
    func calculateMenuTopOffset() -> CGFloat {
        calculateOffsetForContentView()
        + contentViewSize.height
        + minContentsSpace
    }
    
    func calculateLeadingOffset(for width: CGFloat) -> CGFloat {
        (locationOnScreen.x + contentViewSize.width) - width
    }
    
    func isNeedToMoveFromTrailing() -> Bool {
        return UIScreen.main.bounds.width < locationOnScreen.x + menuSize.width + minBottomOffset
    }
    
    func calculateOffsetForUpperContentView() -> CGFloat {
        let offset = calculateOffsetForContentView()
        - (upperContentSize.height + minContentsSpace)
        
        return offset < .zero
        ? minBottomOffset
        : offset
    }
    
    func calculateOffsetForContentView() -> CGFloat {
        guard !isShoudScroll() else {
            return minBottomOffset
        }
        
        if isNeedToMoveFromBottom(
            for: locationOnScreen.y + contentViewSize.height
        ) {
            return getOffsetToMoveFromBottom()
        }
        
        if isNeedToMoveFromTop() {
            return getOffsetToMoveFromTop()
        }
        
        return locationOnScreen.y
    }
    
    func isShoudScroll() -> Bool {
        guard contentViewSize.height
                + menuSize.height
                + minBottomOffset
                < UIScreen.main.bounds.height
        else {
            return true
        }
        
        return false
    }
    
    func isNeedToMoveFromTop() -> Bool {
        locationOnScreen.y - minContentsSpace - upperContentSize.height < minBottomOffset
    }
    
    func getOffsetToMoveFromTop() -> CGFloat {
        minContentsSpace
        + upperContentSize.height
        + minBottomOffset
    }
    
    func isNeedToMoveFromBottom(for bottomPosition: CGFloat) -> Bool {
        UIScreen.main.bounds.height - bottomPosition < (menuSize.height + minBottomOffset)
    }
    
    func getOffsetToMoveFromBottom() -> CGFloat {
        UIScreen.main.bounds.height
        - menuSize.height
        - contentViewSize.height
        - minBottomOffset
    }
    
}

private let animationDuration: TimeInterval = 0.2
private let estimateMenuRowHeight: CGFloat = 50
private let minBottomOffset: CGFloat = 50
private let minContentsSpace: CGFloat = 15
