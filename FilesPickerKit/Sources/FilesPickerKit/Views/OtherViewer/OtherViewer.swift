//
//  OtherViewer.swift
//
//
//  Created by Stanislav Jelezoglo on 12.03.2024.
//

import Foundation
import SwiftUI
import CommonKit

struct OtherViewer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OtherViewerViewModel
    
    init(viewModel: OtherViewerViewModel) {
        _viewModel = StateObject(
            wrappedValue: viewModel
        )
    }
    
    public var body: some View {
        VStack {
            if viewModel.viewerShown {
                ViewerContent(viewModel: viewModel, dismissAction: {
                    dismissAction()
                })
                .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.2)))
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
    @ObservedObject var viewModel: OtherViewerViewModel
    
    var dismissAction: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(viewModel.caption)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                    .padding()
                Spacer()
                CloseButton(dismissAction: dismissAction, color: .black)
                    .padding()
            }
            .background(Color(UIColor.tertiarySystemGroupedBackground))
            
            Content(viewModel: viewModel)
            
            HStack {
                Spacer()
                
                Button {
                    viewModel.shareAction()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .frame(width: 22, height: 30)
                        .tint(Color(UIColor.adamant.active))
                }
                .padding(EdgeInsets(top: 5, leading: .zero, bottom: 5, trailing: .zero))
                .sheet(isPresented: viewModel.$isShareSheetPresented) {
                    shareView()
                }
                
                Spacer()
            }
            .background(Color(UIColor.tertiarySystemGroupedBackground))
        }
        .background(Color.white)
    }
    
    func shareView() -> some View {
        if let copyURL = try? viewModel.getCopyOfFile() {
            let completion: UIActivityViewController.CompletionWithItemsHandler = { [weak viewModel] (_, _, _, _) in
                viewModel?.removeCopyOfFile()
            }
            return ShareSheet(activityItems: [copyURL], completion: completion)
        }
        
        return ShareSheet(activityItems: [viewModel.fileUrl], completion: nil)
    }
}

private struct Content: View {
    @ObservedObject var viewModel: OtherViewerViewModel
    
    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .frame(width: 80, height: 90)
            
            Text(viewModel.caption)
                .font(.headline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
            
            if let size = viewModel.size {
                Text(viewModel.formatSize(size))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

private let image: UIImage = UIImage.asset(named: "file-default-box")!
