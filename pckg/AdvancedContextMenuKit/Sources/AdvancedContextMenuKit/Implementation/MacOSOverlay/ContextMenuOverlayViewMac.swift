//
//  ContextMenuOverlayViewMac.swift
//  
//
//  Created by Stanislav Jelezoglo on 13.07.2023.
//

import SwiftUI

struct ContextMenuOverlayViewMac: View {
    @StateObject private var viewModel: ContextMenuOverlayViewModelMac
    
    init(viewModel: ContextMenuOverlayViewModelMac) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            Button(action: {
                viewModel.dismiss()
            }, label: {
                Color.clear
            })
            
            if viewModel.isContextMenuVisible {
                if let upperContentView = viewModel.upperContentView {
                    makeUpperOverlayView(upperContentView: upperContentView)
                }
            }
            makeOverlayView()
            Spacer()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: animationDuration)) {
                viewModel.isContextMenuVisible.toggle()
            }
        }
    }
}

private extension ContextMenuOverlayViewMac {
    func makeOverlayView() -> some View {
        VStack(spacing: 10) {
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
    
    func makeMenuView() -> some View {
        HStack {
            if let menuVC = viewModel.menu {
                AMenuWrapper(view: menuVC)
                    .frame(width: menuVC.menuSize.width, height: menuVC.menuSize.height)
                    .cornerRadius(15)
                    .padding(.top, viewModel.menuLocation.y)
                    .padding(.leading, viewModel.menuLocation.x)
                    .transition(.opacity)
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
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
}

private let animationDuration: TimeInterval = 0.2
