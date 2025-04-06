//
//  AdvancedAlertView.swift
//
//
//  Created by Andrey Golubenko on 12.04.2023.
//

import CommonKit
import SwiftUI

struct AdvancedAlertView: View {
    @State private var width: CGFloat = .zero

    let model: AdvancedAlertModel

    var body: some View {
        VStack(spacing: .zero) {
            VStack(spacing: .zero) {
                iconView
                    .padding(.vertical, bigSpacing)
                if let title = model.title {
                    makeTitleView(title: title)
                        .padding(.bottom, smallSpacing)
                }
                textView
                    .padding(.bottom, bigSpacing)

                if let secondaryButton = model.secondaryButton {
                    makeSecondaryButton(model: secondaryButton)
                        .padding(.bottom, bigSpacing)
                }
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

extension AdvancedAlertView {
    fileprivate struct ViewPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat { .zero }

        static func reduce(value: inout Value, nextValue: () -> Value) {
            value += nextValue()
        }
    }

    fileprivate var iconView: some View {
        Image(uiImage: model.icon)
            .renderingMode(.template)
            .foregroundColor(.secondary)
            .frame(squareSize: 37)
    }

    fileprivate func makeTitleView(title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
    }

    fileprivate var textView: some View {
        Text(model.text)
            .multilineTextAlignment(.center)
            .font(.system(size: 13))
    }

    fileprivate var primaryButton: some View {
        Button(action: model.primaryButton.action.value) {
            Text(model.primaryButton.title)
                .padding(.vertical, bigSpacing)
                .expanded(axes: .horizontal)
        }
    }

    fileprivate var widthReader: some View {
        GeometryReader {
            Color.clear.preference(
                key: ViewPreferenceKey.self,
                value: $0.frame(in: .local).size.width
            )
        }
    }

    fileprivate func makeSecondaryButton(model: AdvancedAlertModel.Button) -> some View {
        Button(model.title, action: model.action.value)
    }
}

private let smallSpacing: CGFloat = 10
private let bigSpacing: CGFloat = 15
