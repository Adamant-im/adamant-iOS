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
            Spacer()
        }
        .ignoresSafeArea()
        .onTapGesture {
            Task {
                await viewModel.dismiss()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: viewModel.animationDuration)) {
                viewModel.additionalMenuVisible.toggle()
            }
        }
    }
}

private extension ContextMenuOverlayView {
    func makeOverlayView() -> some View {
        ScrollView(axes, showsIndicators: false) {
            VStack(spacing: .zero) {
                makeContentView()
                    .onTapGesture { }
                makeMenuView()
                    .onTapGesture { }
                Spacer()
            }
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .ignoresSafeArea()
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
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .ignoresSafeArea()
    }
    
    func makeMenuOverlayView() -> some View {
        VStack {
            makeMenuView()
                .onTapGesture { }
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .ignoresSafeArea()
    }
    
    func makeMenuView() -> some View {
        HStack {
            if viewModel.additionalMenuVisible,
               let menuVC = viewModel.menu {
                UIViewControllerWrapper(menuVC)
                    .frame(width: menuVC.menuSize.width, height: menuVC.menuSize.height)
                    .cornerRadius(15)
                    .padding(.top, viewModel.menuLocation.y)
                    .padding(.leading, viewModel.menuLocation.x)
                    .transition(menuTransition)
                Spacer()
            }
        }
        .frame(width: .infinity, height: .infinity)
        .ignoresSafeArea()
    }
    
    func makeUpperOverlayView(upperContentView: some View) -> some View {
        VStack {
            makeUpperContentView(upperContentView: upperContentView)
                .onTapGesture { }
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .ignoresSafeArea()
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
        .frame(width: .infinity, height: .infinity)
        .ignoresSafeArea()
    }
    
}
