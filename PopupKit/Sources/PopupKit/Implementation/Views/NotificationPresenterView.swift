//
//  NotificationPresenterView.swift
//  PopupKit
//
//  Created by Yana Silosieva on 02.12.2024.
//

import SwiftUI
import CommonKit

struct NotificationPresenterView: View {
    enum DragDirection {
        case vertical
        case horizontal
    }
    
    @State private var verticalDragTranslation: CGFloat = .zero
    @State private var horizontalDragTranslation: CGFloat = .zero
    @State private var minTranslationYForDismiss: CGFloat = .infinity
    @State private var minTranslationXForDismiss: CGFloat = .infinity
    @State private var isTextLimited: Bool = true
    @State private var dismissEdge: Edge = .top
    @State private var dragDirection: DragDirection? 
    
    let model: NotificationModel
    let safeAreaInsets: EdgeInsets
    let dismissAction: () -> Void
    
    var body: some View {
        NotificationView(
            isTextLimited: $isTextLimited,
            model: model
        )
        .padding([.leading, .trailing], 10)
        .padding([.top, .bottom], 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.init(uiColor:.adamant.chatInputBarBorderColor), lineWidth: 1)
        )
        .background(GeometryReader(content: processGeometry))
        .expanded(axes: .horizontal)
        .offset(y: verticalDragTranslation < .zero ? verticalDragTranslation : .zero)
        .offset(x: horizontalDragTranslation < .zero ? horizontalDragTranslation : .zero)
        .gesture(dragGesture)
        .onTapGesture(perform: onTap)
        .cornerRadius(10)
        .padding(.horizontal, 15)
        .padding(.top, safeAreaInsets.top)
        .transition(.move(edge: dismissEdge))
    }
}

private extension NotificationPresenterView {
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged {
                if dragDirection == nil {
                    dragDirection = abs($0.translation.height) > abs($0.translation.width) ? .vertical : .horizontal
                }
                switch dragDirection {
                case .vertical:
                    verticalDragTranslation = $0.translation.height
                case .horizontal:
                    horizontalDragTranslation = $0.translation.width
                case .none:
                    break
                }
            }
            .onEnded {
                if $0.velocity.height < -100 || -$0.translation.height > minTranslationYForDismiss {
                        dismissEdge = .top
                    Task { dismissAction() }
                } else if $0.velocity.width < -100 || $0.translation.width > minTranslationXForDismiss {
                        dismissEdge = .leading
                    Task { dismissAction() }
                } else if $0.velocity.height > -100 || -$0.translation.height < minTranslationYForDismiss {
                    withAnimation {
                        horizontalDragTranslation = .zero
                        isTextLimited = false
                    }
                    model.cancelAutoDismiss?.value()
                } else {
                    withAnimation {
                        verticalDragTranslation = .zero
                        horizontalDragTranslation = .zero
                    }
                }
                dragDirection = nil
            }
    }
    
    func processGeometry(_ geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            minTranslationYForDismiss = geometry.size.height / 2
            minTranslationXForDismiss = geometry.size.width / 2
        }

        return Color.init(uiColor: .adamant.swipeBlockColor)
            .cornerRadius(10)
    }
    
    func onTap() {
        model.tapHandler?.value()
        dismissAction()
        dismissEdge = .top
    }
}
