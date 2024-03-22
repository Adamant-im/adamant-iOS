//
//  ImageViewer.swift
//
//
//  Created by Stanislav Jelezoglo on 11.03.2024.
//

import Foundation
import SwiftUI
import CommonKit
import Combine

public struct ImageViewer: View {
    @StateObject private var viewModel: ImageViewerViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(image: UIImage, caption: String? = nil) {
        _viewModel = StateObject(
            wrappedValue: ImageViewerViewModel(image: image, caption: caption)
        )
    }
    
    public var body: some View {
        VStack {
            if viewModel.viewerShown {
                ViewerContent(viewModel: viewModel, dismissAction: {
                    dismissAction()
                })
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
                    .onAppear {
                        resetDragOffset()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animateViewer()
        }
    }
    
    private func animateViewer() {
        Task {
            await animate(duration: 0.25) {
                viewModel.viewerShown.toggle()
            }
        }
    }
    
    private func resetDragOffset() {
        viewModel.dragOffset = .zero
        viewModel.dragOffsetPredicted = .zero
    }
    
    private func dismissAction() {
        Task {
            await animate(duration: 0.25) {
                viewModel.viewerShown = false
            }
            
            dismiss()
        }
    }
}

private struct ViewerContent: View {
    @ObservedObject var viewModel: ImageViewerViewModel
    var dismissAction: () -> Void
    
    var body: some View {
        ZStack {
            ViewerControls(viewModel: viewModel, dismissAction: dismissAction)

            ImageContent(viewModel: viewModel, dismissAction: dismissAction)
        }
        .background(backgroundOpacity())
    }
    
    private func backgroundOpacity() -> Color {
        Color(
            red: 0.12,
            green: 0.12,
            blue: 0.12,
            opacity: (1.0 - Double(abs(viewModel.dragOffset.width) + abs(viewModel.dragOffset.height)) / 1000)
        )
    }
}

private struct ViewerControls: View {
    @ObservedObject var viewModel: ImageViewerViewModel
    
    var dismissAction: () -> Void
    
    @State private var isShareSheetPresented = false
    
    var body: some View {
        VStack {
            HStack {
                if let caption = viewModel.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .padding()
                }
                Spacer()
                CloseButton(dismissAction: dismissAction, color: .white)
                    .padding()
            }
            .background(Color.black.opacity(0.5))
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button {
                    isShareSheetPresented.toggle()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .frame(width: 22, height: 30)
                        .tint(.white)
                }
                .padding()
                .sheet(isPresented: $isShareSheetPresented) {
                    ShareSheet(activityItems: [viewModel.uiImage], completion: nil)
                }
                
                Spacer()
            }
            .background(Color.black.opacity(0.5))
        }
        .zIndex(2)
    }
}

struct CloseButton: View {
    var dismissAction: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: dismissAction) {
            Image(systemName: "xmark")
                .foregroundColor(color)
                .font(.system(size: UIFontMetrics.default.scaledValue(for: 24)))
        }
    }
}

private struct ImageContent: View {
    @ObservedObject var viewModel: ImageViewerViewModel
    var dismissAction: () -> Void
    
    var body: some View {
        VStack {
            viewModel.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(x: viewModel.dragOffset.width, y: viewModel.dragOffset.height)
                .rotationEffect(.init(degrees: Double(viewModel.dragOffset.width / 30)))
                .pinchToZoom()
                .gesture(dragGesture())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                viewModel.dragOffset = value.translation
                viewModel.dragOffsetPredicted = value.predictedEndTranslation
            }
            .onEnded { _ in
                handleDragEnd()
            }
    }
    
    private func handleDragEnd() {
        if viewModel.shouldDismissViewer() {
            withAnimation(.spring()) {
                viewModel.dragOffset = viewModel.dragOffsetPredicted
            }
            dismissAction()
        } else {
            withAnimation(.interactiveSpring()) {
                viewModel.dragOffset = .zero
            }
        }
    }
}
