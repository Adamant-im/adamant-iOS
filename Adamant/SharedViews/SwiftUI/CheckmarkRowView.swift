//
//  CheckmarkRowView.swift
//  Adamant
//
//  Created by Andrey Golubenko on 01.08.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import SwiftUI

struct CheckmarkRowView: UIViewRepresentable {
    private let isChecked: Binding<Bool>
    private let title: String?
    private let subtitle: String?
    private let caption: String?
    private let captionColor: UIColor
    private let checkmarkImage: UIImage?
    private let isUpdating: Bool
    private let checkmarkImageTintColor: UIColor?
    
    init(
        isChecked: Binding<Bool>,
        title: String?,
        subtitle: String?,
        caption: String?,
        checkmarkImage: UIImage?,
        captionColor: UIColor = .label,
        isUpdating: Bool = false,
        checkmarkImageTintColor: UIColor? = nil
    ) {
        self.isChecked = isChecked
        self.title = title
        self.subtitle = subtitle
        self.caption = caption
        self.captionColor = captionColor
        self.checkmarkImage = checkmarkImage
        self.isUpdating = isUpdating
        self.checkmarkImageTintColor = checkmarkImageTintColor
    }
    
    func makeUIView(context _: Context) -> UICheckmarkRowView {
        .init()
    }
    
    func updateUIView(_ uiView: UICheckmarkRowView, context: Context) {
        uiView.title = title
        uiView.subtitle = subtitle
        uiView.caption = caption
        uiView.checkmarkImage = checkmarkImage
        uiView.captionColor = captionColor
        uiView.checkmarkImageTintColor = checkmarkImageTintColor
        uiView.setIsUpdating(isUpdating, animated: true)
        uiView.setIsChecked(isChecked.wrappedValue, animated: true)
        
        uiView.onCheckmarkTap = { [weak uiView, isChecked] in
            guard let uiView = uiView else { return }
            isChecked.wrappedValue = uiView.isChecked
        }
    }
}
