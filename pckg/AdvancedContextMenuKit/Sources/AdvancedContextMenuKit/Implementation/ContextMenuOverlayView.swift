//
//  ContextMenuOverlayView.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

protocol OverlayViewDelegate: NSObject {
    func didDissmis()
    func didDisplay()
}

struct ContextMenuOverlayView: View {
    let contentView: UIView
    let topYOffset: CGFloat
    let newContentHeight: CGFloat
    let oldContentHeight: CGFloat
    let newContentWidth: CGFloat
    let menu: UIMenu
    let menuAlignment: Alignment
    let upperContentView: AnyView?
    let upperContentHeight: CGFloat
    
    @State private var isPresented = true
    @State private var menuHeight: CGFloat = .zero
    @State private var isContextMenuVisible = false
    
    @Environment(\.dismiss) var dismiss
    
    var backgroundBlur: Blur {
        Blur(style: .systemUltraThinMaterialDark, sensetivity: 0.5)
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
    
    var topOfContentViewOffset: CGFloat {
        topYOffset// - (newContentHeight - oldContentHeight) / 2
    }
    
    weak var delegate: OverlayViewDelegate?
    
    var body: some View {
        ZStack {
            if isContextMenuVisible {
                backgroundBlur
                    .ignoresSafeArea(.all)
                
                if let upperContentView = upperContentView {
                    makeUpperOverlayView(upperContentView: upperContentView)
                }
            }
            makeOverlayView()
            Spacer()
        }
        .ignoresSafeArea()
        .onTapGesture {
            withAnimation(.easeInOut(duration: animationDuration)) {
                isContextMenuVisible.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                delegate?.didDissmis()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration)) {
                isContextMenuVisible.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                delegate?.didDisplay()
            }
        }
    }
}

private extension ContextMenuOverlayView {
    func makeOverlayView() -> some View {
        VStack(spacing: 10) {
            makeContentView()
                .onTapGesture { }
            if isContextMenuVisible {
                makeMenuView()
                    .onTapGesture { }
            }
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeUpperOverlayView(upperContentView: some View) -> some View {
        VStack {
            makeUpperContentView(upperContentView: upperContentView)
                .onTapGesture { }
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeUpperContentView(upperContentView: some View) -> some View {
        upperContentView
            .frame(height: upperContentHeight)
            .padding(.top,
                getTopPaddingForContentView()
                - (upperContentHeight + minContentsSpace)
            )
            .padding([.leading, .trailing], 16)
    }
    
    func makeContentView() -> some View {
        UIViewWrapper(view: contentView)
            .frame(height: newContentHeight)
            .padding(.top, getTopPaddingForContentView())
            .padding([.leading, .trailing], 8)
          //  .padding(.leading, 8)
           // .scaleEffect(0.9)
           // .transition(transition)
    }
    
    func makeMenuView() -> some View {
        MenuView(menu: menu)
            .padding([.leading, .trailing], 16)
            .frame(maxWidth: .infinity, alignment: menuAlignment)
            .background(GeometryReader { menuGeometry in
                Color.clear
                    .onAppear {
                        menuHeight = menuGeometry.size.height
                    }
            })
            .transition(menuTransition)
    }
}

private extension ContextMenuOverlayView {
    func getTopPaddingForContentView() -> CGFloat {
        guard isContextMenuVisible else {
            return topOfContentViewOffset
        }
        
        if isNeedToMoveFromBottom(for: topYOffset + newContentHeight) {
            return getOffsetToMoveFromBottom()
        }
        
        if isNeedToMoveFromTop() {
            return getOffsetToMoveFromTop()
        }
        
        return topOfContentViewOffset
    }
    
    func isNeedToMoveFromTop() -> Bool {
        topOfContentViewOffset - minContentsSpace - upperContentHeight < minBottomOffset
    }
    
    func getOffsetToMoveFromTop() -> CGFloat {
        minContentsSpace
        + upperContentHeight
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
}

private let animationDuration: TimeInterval = 0.2
private let minBottomOffset: CGFloat = 50
private let minContentsSpace: CGFloat = 10
