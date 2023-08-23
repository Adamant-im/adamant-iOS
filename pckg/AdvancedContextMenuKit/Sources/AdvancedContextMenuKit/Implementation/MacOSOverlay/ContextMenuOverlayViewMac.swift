//
//  ContextMenuOverlayViewMac.swift
//  
//
//  Created by Stanislav Jelezoglo on 13.07.2023.
//

import SwiftUI
import CommonKit

@MainActor
struct ContextMenuOverlayViewMac: View {
    @StateObject private var viewModel: ContextMenuOverlayViewModelMac
    
    init(viewModel: ContextMenuOverlayViewModelMac) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            makeStackView(geometry: geometry)
        }
    }
}

private extension ContextMenuOverlayViewMac {
    func makeStackView(geometry: GeometryProxy) -> some View {
        ZStack {
            viewModel.updateLocations(geometry: geometry)
            
            Button(action: {
                Task {
                    await viewModel.dismiss()
                }
            }, label: {
                if viewModel.additionalMenuVisible {
                    Color.init(uiColor: .adamant.contextMenuOverlayMacColor)
                } else {
                    Color.clear
                }
            })
            
            makeContentOverlayView()
            
            if viewModel.additionalMenuVisible {
                if let upperContentView = viewModel.upperContentView {
                    makeUpperOverlayView(upperContentView: upperContentView)
                }
            }
            makeOverlayView()
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await animate(duration: viewModel.animationDuration) {
                    viewModel.additionalMenuVisible.toggle()
                }
                viewModel.delegate?.didAppear()
            }
        }
    }

    func makeOverlayView() -> some View {
        VStack(spacing: 10) {
            if viewModel.additionalMenuVisible {
                makeMenuView()
                    .onTapGesture { }
            }
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeContentOverlayView() -> some View {
        VStack(spacing: 10) {
            makeContentView()
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeContentView() -> some View {
        HStack {
            UIViewWrapper(view: viewModel.contentView)
                .frame(
                    width: viewModel.contentViewSize.width,
                    height: viewModel.contentViewSize.height
                )
                .padding(.top, viewModel.contentLocation.y)
                .padding(.leading, viewModel.contentLocation.x)
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
    
    func makeMenuView() -> some View {
        HStack {
            if let menuVC = viewModel.menu {
                UIViewControllerWrapper(menuVC)
                    .frame(width: menuVC.menuSize.width, height: menuVC.menuSize.height)
                    .cornerRadius(15)
                    .padding(.top, viewModel.menuLocation.y)
                    .padding(.leading, viewModel.menuLocation.x)
                    .transition(.opacity)
            }
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
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
                .padding(.top, viewModel.upperContentViewLocation.y)
                .padding(.leading, viewModel.upperContentViewLocation.x)
            Spacer()
        }
        .fullScreen()
        .transition(.opacity)
    }
}

private let animationDuration: TimeInterval = 0.2
