//
//  NotificationView.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI
import CommonKit

struct NotificationView: View {
    @State private var dragTranslation: CGFloat = .zero
    @State private var horizontalDragTranslation: CGFloat = .zero
    @State private var minTranslationForDismiss: CGFloat = .infinity
    @State private var minTranslationXForDismiss: CGFloat = .infinity
    @State private var isTextLimited: Bool = true
    
    @Binding var dismissEdge: Edge
    var onDismissEdgeChanged: ((Edge) -> Void)?
    let model: NotificationModel
    let safeAreaInsets: EdgeInsets
    let dismissAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if let icon = model.icon {
                makeIcon(image: icon)
            }
            textStack
            Spacer(minLength: .zero)
        }
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

private extension NotificationView {
    func makeIcon(image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .renderingMode(.original)
            .foregroundColor(.secondary)
            .scaledToFit()
            .frame(squareSize: 30)
            .padding(.top, 2)
    }
    
    var textStack: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let title = model.title {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            if let description = model.description {
                Text(description)
                    .font(.system(size: 13))
                    .lineLimit(isTextLimited ? 3 : nil)
               
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged {
                dragTranslation = $0.translation.height
                horizontalDragTranslation = $0.translation.width
            }
            .onEnded {
                if $0.velocity.height < -100 || -$0.translation.height > minTranslationForDismiss {
                    onDismissEdgeChanged?(.top)
                    Task {
                        dismissAction()
                    }
                } else if $0.velocity.width < -100 || $0.translation.width > minTranslationXForDismiss {
                    onDismissEdgeChanged?(.leading)
                    Task {
                        dismissAction()
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
        dismissAction()
    }
}
