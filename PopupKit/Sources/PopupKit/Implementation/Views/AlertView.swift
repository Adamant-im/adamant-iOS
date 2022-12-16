//
//  AlertView.swift
//  
//
//  Created by Andrey Golubenko on 06.12.2022.
//

import SwiftUI

struct AlertView: View {
    let model: AlertModel
    
    var body: some View {
        VStack(spacing: 8) {
            iconView
            if let message = model.message {
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16.5)
        .background(Blur(style: Constants.blurStyle))
        .cornerRadius(Constants.cornerRadius)
        .padding(Constants.borderPadding)
    }
}

private extension AlertView {
    var iconView: some View {
        Group {
            switch model.icon {
            case .loading:
                ProgressView()
                    .scaleEffect(1.5)
            case let .image(image):
                Image(uiImage: image)
                    .renderingMode(.template)
                    .foregroundColor(.primary)
            }
        }.frame(squareSize: 37)
    }
}
