//
//  NotificationPresenterView.swift
//  PopupKit
//
//  Created by Yana Silosieva on 02.12.2024.
//

import SwiftUI
import CommonKit

struct NotificationPresenterView: View {
    @State private var dragTranslation: CGFloat = .zero
    @State private var horizontalDragTranslation: CGFloat = .zero
    @State private var minTranslationForDismiss: CGFloat = .infinity
    @State private var minTranslationXForDismiss: CGFloat = .infinity
    @State private var isTextLimited: Bool = true
    
    let model: NotificationModel
    let safeAreaInsets: EdgeInsets
    let dismissAction: ((Edge)) -> Void
    
    var body: some View {
        NotificationView(
            isTextLimited: $isTextLimited,
            model: model
        )
        .padding([.leading, .trailing], 15)
        .padding([.top, .bottom], 10)
        .background(GeometryReader(content: processGeometry))
        .expanded(axes: .horizontal)
        .offset(y: dragTranslation < .zero ? dragTranslation : .zero)
        .offset(x: horizontalDragTranslation < .zero ? horizontalDragTranslation : .zero)
        .gesture(dragGesture)
        .onTapGesture(perform: onTap)
        .cornerRadius(10)
        .padding(.horizontal, 15)
        .padding(.top, safeAreaInsets.top)
    }
}

private extension NotificationPresenterView {
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged {
                dragTranslation = $0.translation.height
                horizontalDragTranslation = $0.translation.width
            }
            .onEnded {
                if $0.velocity.height < -100 || -$0.translation.height > minTranslationForDismiss {
                    Task {
                        dismissAction(.top)
                    }
                } else if $0.velocity.width < -100 || $0.translation.width > minTranslationXForDismiss {
                    Task {
                        dismissAction(.leading)
                    }
                } else if $0.velocity.height > -100 || -$0.translation.height < minTranslationForDismiss {
                    horizontalDragTranslation = .zero
                    isTextLimited = false
                    model.cancelAutoDismiss?.value()
                } else {
                    withAnimation {
                        dragTranslation = .zero
                        horizontalDragTranslation = .zero
                    }
                }
            }
    }
    
    func processGeometry(_ geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            minTranslationForDismiss = geometry.size.height / 2
            minTranslationXForDismiss = geometry.size.width / 2
        }

        return Color.init(uiColor: .adamant.swipeBlockColor)
            .cornerRadius(10)
    }
    
    func onTap() {
        model.tapHandler?.value()
        dismissAction(.top)
    }
}
