//
//  AdvancedAlertView.swift
//  
//
//  Created by Andrey Golubenko on 12.04.2023.
//

import SwiftUI

struct AdvancedAlertView: View {
    @State private var width: CGFloat = .zero
    
    let model: AdvancedAlertModel
    
    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: .zero) {
                iconView
                    .padding(.vertical, bigSpacing)
                titleView
                    .padding(.bottom, smallSpacing)
                textView
                    .padding(.bottom, bigSpacing)
                secondaryButton
                    .padding(.bottom, bigSpacing)
            }.padding(.horizontal, bigSpacing)
            .background(widthReader)
            .onPreferenceChange(ViewPreferenceKey.self) { width = $0 }
            
            Group {
                Divider()
                primaryButton
            }.frame(width: width)
        }
        .background(Blur(style: Constants.blurStyle))
        .cornerRadius(Constants.cornerRadius)
        .padding(Constants.borderPadding)
    }
}

private extension AdvancedAlertView {
    struct ViewPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat { .zero }
        
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value += nextValue()
        }
    }
    
    var iconView: some View {
        Image(uiImage: model.icon)
            .renderingMode(.template)
            .foregroundColor(.primary)
            .frame(squareSize: 37)
    }
    
    var titleView: some View {
        Text(model.title)
            .font(.system(size: 17, weight: .bold))
    }
    
    var textView: some View {
        Text(model.text)
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
    }
    
    var secondaryButton: some View {
        Button(
            model.secondaryButton.title,
            action: model.secondaryButton.action.action
        )
    }
    
    var primaryButton: some View {
        Button(action: model.primaryButton.action.action) {
            Text(model.primaryButton.title)
                .padding(.vertical, bigSpacing)
                .expanded(.horizontal)
        }
    }
    
    var widthReader: some View {
        GeometryReader {
            Color.clear.preference(
                key: ViewPreferenceKey.self,
                value: $0.frame(in: .local).size.width
            )
        }
    }
}

private let smallSpacing: CGFloat = 10
private let bigSpacing: CGFloat = 15
