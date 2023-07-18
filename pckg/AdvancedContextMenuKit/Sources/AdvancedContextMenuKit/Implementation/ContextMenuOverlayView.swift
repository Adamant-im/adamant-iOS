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
    
    func makeContentView() -> some View {
        HStack {
            UIViewWrapper(view: viewModel.contentView)
                .frame(
                    width: viewModel.contentViewSize.width,
                    height: viewModel.contentViewSize.height
                )
                .padding(.top,
                         viewModel.isContextMenuVisible
                         ? viewModel.finalOffsetForContentView
                         : viewModel.startOffsetForContentView
                )
                .padding(.leading, viewModel.locationOnScreen.x)
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeMenuView() -> some View {
        HStack {
            MenuView(menu: viewModel.menu)
                .frame(width: viewModel.menuWidth)
                .padding(.leading, viewModel.menuLocation.x)
                .transition(viewModel.menuTransition)
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(viewModel.menuTransition)
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
            if viewModel.menuAlignment == .trailing {
                Spacer()
            }
            upperContentView
                .frame(width: viewModel.upperContentSize.width, height: viewModel.upperContentSize.height)
                .padding(.top,
                         viewModel.isContextMenuVisible
                         ? viewModel.finalOffsetForUpperContentView
                         : viewModel.startOffsetForUpperContentView
                )
                .padding(.leading, viewModel.upperContentViewLocation.x)
            if viewModel.menuAlignment == .leading {
                Spacer()
            }
        }
    }
    
}

private let animationDuration: TimeInterval = 0.2
