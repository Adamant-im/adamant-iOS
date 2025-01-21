//
//  NotificationView.swift
//
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI
import CommonKit

struct NotificationView: View {
    @Binding var isTextLimited: Bool
    let model: NotificationModel
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            HStack(alignment: .top, spacing: 10) {
                if let icon = model.icon {
                    makeIcon(image: icon)
                }
                textStack
                Spacer(minLength: .zero)
            }
            Image(systemName: isTextLimited ? pullDownIcon : pullUpIcon)
                .font(.title)
                .foregroundColor(.gray)
        }
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
}

private let pullDownIcon = "chevron.compact.down"
private let pullUpIcon = "chevron.compact.up"
