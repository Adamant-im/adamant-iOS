//
//  ContextMenuOverlayView.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

protocol OverlayViewDelegate: AnyObject {
    func didDissmis()
    func didDisplay()
}

struct ContextMenuOverlayView: View {
    @StateObject private var viewModel: ContextMenuOverlayViewModel
    
    init(viewModel: ContextMenuOverlayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var backgroundBlur: Blur {
        Blur(style: .systemUltraThinMaterialDark, sensetivity: 0.5)
    }
    
    var body: some View {
        ZStack {
            if viewModel.isContextMenuVisible {
                backgroundBlur
                    .ignoresSafeArea(.all)
                
                if let upperContentView = viewModel.upperContentView {
                    makeUpperOverlayView(upperContentView: upperContentView)
                }
            }
            makeOverlayView()
            Spacer()
        }
        .ignoresSafeArea()
        .onTapGesture {
            viewModel.dismiss()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration)) {
                viewModel.isContextMenuVisible.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                viewModel.delegate?.didDisplay()
            }
        }
    }
}

private extension ContextMenuOverlayView {
    func makeOverlayView() -> some View {
        VStack(spacing: 10) {
            makeContentView()
                .onTapGesture { }
            if viewModel.isContextMenuVisible {
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
            .frame(height: viewModel.upperContentHeight)
            .padding(.top,
                     getTopPaddingForContentView()
                        - (viewModel.upperContentHeight + minContentsSpace)
            )
            .padding([.leading, .trailing], 16)
    }
    
    func makeContentView() -> some View {
        UIViewWrapper(view: viewModel.contentView)
            .frame(height: viewModel.newContentHeight)
            .padding(.top, getTopPaddingForContentView())
            .padding([.leading, .trailing], viewModel.superViewXOffset)
    }
    
    func makeMenuView() -> some View {
        MenuView(menu: viewModel.menu)
            .padding([.leading, .trailing], 16)
            .frame(maxWidth: .infinity, alignment: viewModel.menuAlignment)
            .background(GeometryReader { menuGeometry in
                Color.clear
                    .onAppear {
                        viewModel.menuHeight = menuGeometry.size.height
                    }
            })
            .transition(viewModel.menuTransition)
    }
    
    func getTopPaddingForContentView() -> CGFloat {
        guard viewModel.isContextMenuVisible else {
            return viewModel.topOfContentViewOffset
        }
        
        if viewModel.isNeedToMoveFromBottom(for: viewModel.topYOffset + viewModel.newContentHeight) {
            return viewModel.getOffsetToMoveFromBottom()
        }
        
        if viewModel.isNeedToMoveFromTop() {
            return viewModel.getOffsetToMoveFromTop()
        }
        
        return viewModel.topOfContentViewOffset
    }
}

private let animationDuration: TimeInterval = 0.2
private let minContentsSpace: CGFloat = 10
