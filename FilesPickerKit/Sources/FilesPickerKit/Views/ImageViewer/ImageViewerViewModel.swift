//
//  ImageViewerViewModel.swift
//
//
//  Created by Stanislav Jelezoglo on 12.03.2024.
//

import Foundation
import SwiftUI
import CommonKit

final class ImageViewerViewModel: ObservableObject {
    @Published var viewerShown: Bool = false
    @Published var image: Image
    @Published var uiImage: UIImage
    @Published var caption: String?
    @Published var dragOffset: CGSize = CGSize.zero
    @Published var dragOffsetPredicted: CGSize = CGSize.zero
    
    var dismissAction: (() -> Void)?
    let presentSendTokensVC = ObservableSender<Void>()
    
    init(image: UIImage, caption: String? = nil) {
        self.uiImage = image
        self.image = .init(uiImage: image)
        self.caption = caption
    }
    
    func shouldDismissViewer() -> Bool {
        (abs(dragOffset.height) + abs(dragOffset.width) > 570) ||
        ((abs(dragOffsetPredicted.height)) / (abs(dragOffset.height)) > 3) ||
        ((abs(dragOffsetPredicted.width)) / (abs(dragOffset.width))) > 3
    }
}
