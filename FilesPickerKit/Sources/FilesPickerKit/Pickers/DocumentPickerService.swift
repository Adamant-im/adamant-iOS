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

public final class DocumentPickerService: NSObject, FilePickerProtocol {
    private var helper = FilesPickerKitHelper()

    public var onPreparedDataCallback: ((Result<[FileResult], Error>) -> Void)?
    public var onPreparingDataCallback: (() -> Void)?
    
    public override init() { }
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
