//
//  File.swift
//  
//
//  Created by Stanislav Jelezoglo on 21.02.2024.
//

import Foundation
import UIKit
import CommonKit
import MobileCoreServices
import AVFoundation

public final class DocumentPickerService: NSObject, FilePickerServiceProtocol {
    private var helper: FilesPickerProtocol

    public var onPreparedDataCallback: ((Result<[FileResult], Error>) -> Void)?
    public var onPreparingDataCallback: (() -> Void)?
    
    public init(helper: FilesPickerProtocol) {
        self.helper = helper
        super.init()
    }
}

extension DocumentPickerService: UIDocumentPickerDelegate {
    public func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        let files = urls.compactMap {
            try? helper.getFileResult(for: $0)
        }
        
        do {
            try helper.validateFiles(files)
            onPreparedDataCallback?(.success(files))
        } catch {
            onPreparedDataCallback?(.failure(error))
        }
    }
}
