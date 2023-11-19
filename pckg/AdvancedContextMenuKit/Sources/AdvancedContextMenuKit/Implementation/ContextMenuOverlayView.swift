//
//  ContextMenuOverlayView.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI
import CommonKit

struct ContextMenuOverlayView: View {
    @StateObject private var viewModel: ContextMenuOverlayViewModel
    
    init(viewModel: ContextMenuOverlayViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var backgroundBlur: Blur {
        Blur(style: .systemUltraThinMaterialDark, sensetivity: 0.5)
    }
    
    var axes: Axis.Set {
        return viewModel.shouldScroll ? .vertical : []
    }
    
    var menuTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .scale(scale: 0, anchor: .top),
            removal: AnyTransition.opacity.combined(
                with: .scale(scale: 0, anchor: .top)
            )
        )
    }
    
    var body: some View {
        ZStack {
            if viewModel.additionalMenuVisible {
                backgroundBlur
                    .zIndex(0)
                    .ignoresSafeArea()
                
                if let upperContentView = viewModel.upperContentView {
                    makeUpperOverlayView(upperContentView: upperContentView)
                        .zIndex(2)
                }
            }
            makeOverlayView()
                .zIndex(1)
            makeMenuOverlayView()
                .zIndex(3)
            Spacer()
        }
        .ignoresSafeArea()
        .onTapGesture {
            Task {
                await viewModel.dismiss()
            }
        }
        .onAppear {
            Task {
                await animate(duration: viewModel.animationDuration) {
                    viewModel.additionalMenuVisible.toggle()
                }
                viewModel.delegate?.didAppear()
                viewModel.scrollToEnd = true
            }
        }
    }
}

private extension ContextMenuOverlayView {
    func makeOverlayView() -> some View {
        makeOverlayScrollToBottom(makeOverlayScrollView())
    }
    
    func makeOverlayScrollView() -> some View {
        ScrollView(axes, showsIndicators: false) {
            VStack(spacing: .zero) {
                makeContentView()
                    .onTapGesture { }
                Spacer()
                    .frame(
                        height: viewModel.menuSize.height
                        + minBottomOffset
                        + minContentsSpace
                    )
            }
            .id(1)
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeOverlayScrollToBottom(_ content: some View) -> some View {
        return ScrollViewReader { value in
            content
                .onChange(of: viewModel.scrollToEnd) { scrollToBottom in
                    guard scrollToBottom else { return }
                    
                    withAnimation {
                        value.scrollTo(1, anchor: .bottom)
                    }
                }
        }
    }
    
    func makeContentView() -> some View {
        HStack {
            UIViewWrapper(view: viewModel.contentView)
                .frame(
                    width: viewModel.contentViewSize.width,
                    height: viewModel.contentViewSize.height
                )
                .padding(.top,
                         viewModel.additionalMenuVisible
                         ? viewModel.contentViewLocation.y
                         : viewModel.startOffsetForContentView
                )
                .padding(.leading, viewModel.contentViewLocation.x)
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeMenuOverlayView() -> some View {
        VStack {
            makeMenuView()
                .onTapGesture { }
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeMenuView() -> some View {
        HStack {
            if viewModel.additionalMenuVisible,
               let menuVC = viewModel.menu {
                UIViewControllerWrapper(menuVC)
                    .frame(width: menuVC.menuSize.width, height: menuVC.menuSize.height)
                    .cornerRadius(15)
                    .padding(.leading, viewModel.menuLocation.x)
                    .transition(menuTransition)
                Spacer()
            }
        }
        .frame(
            width: .infinity,
            height: viewModel.menuSize.height
        )
        .offset(y: viewModel.menuLocation.y)
        .ignoresSafeArea()
    }
    
    func makeUpperOverlayView(upperContentView: some View) -> some View {
        VStack {
            makeUpperContentView(upperContentView: upperContentView)
                .onTapGesture { }
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeUpperContentView(upperContentView: some View) -> some View {
        HStack {
            upperContentView
                .frame(
                    width: viewModel.upperContentSize.width,
                    height: viewModel.upperContentSize.height
                )
                .padding(.top,
                         viewModel.additionalMenuVisible
                         ? viewModel.upperContentViewLocation.y
                         : viewModel.startOffsetForUpperContentView
                )
                .padding(.leading, viewModel.upperContentViewLocation.x)
            Spacer()
        }
        .fullScreen()
    }
    
}

private let minBottomOffset: CGFloat = 50
private let minContentsSpace: CGFloat = 15
