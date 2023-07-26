//
//  ContextMenuOverlayView.swift
//  
//
//  Created by Stanislav Jelezoglo on 23.06.2023.
//

import SwiftUI

protocol OverlayViewDelegate: AnyObject {
    func didDissmis()
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
                    .zIndex(0)
                    .ignoresSafeArea(.all)
                
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
            viewModel.dismiss()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration)) {
                viewModel.isContextMenuVisible.toggle()
            }
        }
    }
}

private extension ContextMenuOverlayView {
    func makeOverlayView() -> some View {
        ScrollView(.vertical) {
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
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeContentView() -> some View {
        HStack {
            UIViewWrapper(view: viewModel.contentView)
                .frame(
                    width: viewModel.contentViewSize.width,
                    height: viewModel.contentViewSize.height
                )
                .padding(.top,
                         viewModel.isContextMenuVisible
                         ? viewModel.contentViewLocation.y
                         : viewModel.startOffsetForContentView
                )
                .padding(.leading, viewModel.contentViewLocation.x)
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeMenuOverlayView() -> some View {
        VStack {
            makeMenuView()
                .onTapGesture { }
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeMenuView() -> some View {
        HStack {
            if viewModel.isContextMenuVisible,
               let menuVC = viewModel.menu {
                AMenuWrapper(view: menuVC)
                    .frame(width: menuVC.menuSize.width, height: menuVC.menuSize.height)
                    .cornerRadius(15)
                    .padding(.top, viewModel.menuLocation.y)
                    .padding(.leading, viewModel.menuLocation.x)
                    .transition(viewModel.menuTransition)
                Spacer()
            }
        }
        .frame(width: .infinity, height: .infinity)
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
        HStack {
            upperContentView
                .frame(
                    width: viewModel.upperContentSize.width,
                    height: viewModel.upperContentSize.height
                )
                .padding(.top,
                         viewModel.isContextMenuVisible
                         ? viewModel.upperContentViewLocation.y
                         : viewModel.startOffsetForUpperContentView
                )
                .padding(.leading, viewModel.upperContentViewLocation.x)
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .edgesIgnoringSafeArea(.all)
    }
    
}

private let animationDuration: TimeInterval = 0.2
