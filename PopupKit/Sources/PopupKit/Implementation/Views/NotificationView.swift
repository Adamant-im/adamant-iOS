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
    @State private var minTranslationForDismiss: CGFloat = .infinity
    
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
        .gesture(dragGesture)
        .onTapGesture(perform: onTap)
        .background(Color(.adamant.swipeBlockColor))
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
        VStack(alignment: .leading, spacing: .zero) {
            if let title = model.title {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
            }
            if let description = model.description {
                Text(description)
                    .font(.system(size: 13))
                    .lineLimit(3)
            }
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { dragTranslation = $0.translation.height }
            .onEnded {
                print(-$0.translation.height, minTranslationForDismiss)
                if $0.velocity.height < -100 || -$0.translation.height > minTranslationForDismiss {
                    dismissAction()
                } else {
                    withAnimation { dragTranslation = .zero }
                }
            }
    }
    
    func processGeometry(_ geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            minTranslationForDismiss = geometry.size.height / 2
        }

        return Color.clear
    }
    
    func onTap() {
        model.tapHandler?.value()
        dismissAction()
    }
}
