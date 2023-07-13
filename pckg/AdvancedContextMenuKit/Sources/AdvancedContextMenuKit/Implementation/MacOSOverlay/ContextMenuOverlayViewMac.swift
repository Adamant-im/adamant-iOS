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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                viewModel.delegate?.didDisplay()
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
            MenuView(menu: viewModel.menu)
                .padding(.top, viewModel.locationOnScreen.y)
                .padding(.leading, viewModel.locationOnScreen.x)
                .background(GeometryReader { menuGeometry in
                    Color.clear
                        .onAppear {
                            viewModel.menuHeight = menuGeometry.size.height
                        }
                })
                .transition(.opacity)
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
                .padding(
                    .top,
                    viewModel.locationOnScreen.y
                    - viewModel.upperContentSize.height
                    - minContentsSpace
                )
                .padding(.leading, viewModel.locationOnScreen.x)
            Spacer()
        }
        .frame(width: .infinity, height: .infinity)
        .transition(.opacity)
        .edgesIgnoringSafeArea(.all)
    }
}

private let animationDuration: TimeInterval = 0.2
private let minContentsSpace: CGFloat = 10
