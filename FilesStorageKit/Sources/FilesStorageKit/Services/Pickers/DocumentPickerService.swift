//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//

import Foundation
import UIKit

final class DocumentPickerService: NSObject, FilePickerProtocol {
    let documentPicker = UIDocumentPickerViewController(
        forOpeningContentTypes: [.data, .content],
        asCopy: false
    )

    private var onPreparedDataCallback: (([FileResult]) -> Void)?

    func startPicker(
        window: UIWindow,
        completion: (([FileResult]) -> Void)?
    ) {
        onPreparedDataCallback = completion
        
        documentPicker.allowsMultipleSelection = true
        documentPicker.delegate = self
        UIApplication.shared.topViewController()?.present(documentPicker, animated: true)
    }
}

extension DocumentPickerService: UIDocumentPickerDelegate {
    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        let files = urls.compactMap {
            FileResult.init(
                url: $0,
                type: .other,
                preview: nil,
                size: (try? getFileSize(from: $0)) ?? .zero,
                name: $0.lastPathComponent,
                extenstion: $0.pathExtension
            )
        }
        
        onPreparedDataCallback?(files)
    }
}

private extension DocumentPickerService {
    func getFileSize(from fileURL: URL) throws -> Int64 {
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        guard let fileSize = fileAttributes[.size] as? Int64 else {
            throw FileValidationError.fileNotFound
        }
        
        return fileSize
    }
}
