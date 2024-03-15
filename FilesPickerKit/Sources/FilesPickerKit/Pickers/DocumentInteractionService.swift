//
//  DocumentInteractionService.swift
//
//
//  Created by Stanislav Jelezoglo on 14.03.2024.
//

import Foundation
import UIKit
import CommonKit
import SwiftUI
import WebKit
import QuickLook

final class DocumentInteractionService: NSObject, DocumentInteractionProtocol {
    private var documentInteractionController: UIDocumentInteractionController?
    private var completion: (() -> Void)?
    
    private var url: URL!
    
    func open(url: URL, name: String, completion: (() -> Void)?) {
        self.completion = completion
        self.url = url
        
//        documentInteractionController = UIDocumentInteractionController(url: url)
//        documentInteractionController?.delegate = self
//        
//        guard isMacOS else {
//            documentInteractionController?.presentPreview(animated: true)
//            return
//        }
        
        let vc = UIApplication.shared.topViewController()!
        
//        guard let uiImage = UIImage(contentsOfFile: url.path) else {
//            documentInteractionController?.presentOpenInMenu(from: vc.view.frame, in: vc.view, animated: true)
//            return
//        }
        
//        let view = ImageViewer(image: uiImage, caption: name)
//        present(view: view)
        
        let quickVC = QLPreviewController()
        quickVC.delegate = self
        quickVC.dataSource = self
        quickVC.modalPresentationStyle = .fullScreen
        vc.present(quickVC, animated: true)
        
        documentInteractionController = nil
    }
}

extension DocumentInteractionService: QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        QLPreviewItemEq(url: url)
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        completion?()
    }
}

final class QLPreviewItemEq: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    
    init(url: URL) {
        previewItemURL = url
    }
}

private extension DocumentInteractionService {
    func present(view: some View) {
        let vc = UIHostingController(
            rootView: view
        )
        vc.modalPresentationStyle = .overCurrentContext
        vc.view.backgroundColor = .clear
        UIApplication.shared.topViewController()?.present(vc, animated: false)
    }
}

extension DocumentInteractionService: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.topViewController()!
    }
    
    public func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        documentInteractionController = nil
        completion?()
    }
}
