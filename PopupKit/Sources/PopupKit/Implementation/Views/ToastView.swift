//
//  ToastView.swift
//
//
//  Created by Andrey Golubenko on 07.12.2022.
//

import CommonKit
import SwiftUI

struct ToastView: View {
    @State private var offset: CGSize = .zero
    @State private var isExpanded: Bool = false
    @State private var isTruncated: Bool = false

    let message: String
    let dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(message)
                .multilineTextAlignment(.center)
                .lineLimit(isExpanded ? nil : 3)
                .background(
                    GeometryReader { textGeometry in
                        Text(message)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .background(
                                GeometryReader { fullGeometry in
                                    Color.clear.onAppear {
                                        isTruncated = fullGeometry.size.height > textGeometry.size.height + 1
                                    }
                                }
                            )
                    }
                )

            if isTruncated && !isExpanded {
                Image(systemName: "chevron.compact.down")
                    .foregroundColor(.gray)
            } else if isExpanded {
                Image(systemName: "chevron.compact.up")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Blur(style: Constants.blurStyle))
        .cornerRadius(Constants.cornerRadius)
        .padding(Constants.borderPadding)
        .contentShape(Rectangle())
        .offset(y: offset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        offset = CGSize(
                            width: 0,
                            height: min(value.translation.height, 30)
                        )
                    } else {
                        offset = CGSize(width: 0, height: value.translation.height)
                    }
                }
                .onEnded { value in
                    if value.translation.height < -30 {
                        dismissAction()
                    } else if value.translation.height > 25 && isTruncated {
                        isExpanded = true
                    }
                    offset = .zero
                }
        )
        .animation(.interactiveSpring(), value: offset)
    }
}
