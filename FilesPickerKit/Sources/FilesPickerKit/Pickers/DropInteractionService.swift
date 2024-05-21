//
//  DropInteractionService.swift
//  
//
//  Created by Stanislav Jelezoglo on 27.03.2024.
//

import Foundation
import CommonKit
import UIKit
import UniformTypeIdentifiers

@MainActor
public final class DropInteractionService: NSObject, FilePickerServiceProtocol {
    private var helper: FilesPickerProtocol

    public var onPreparedDataCallback: ((Result<[FileResult], Error>) -> Void)?
    public var onSessionCallback: ((Bool) -> Void)?
    public var onPreparingDataCallback: (() -> Void)?

    public init(helper: FilesPickerProtocol) {
        self.helper = helper
        super.init()
    }
}

extension DropInteractionService: UIDropInteractionDelegate {
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        canHandle session: UIDropSession
    ) -> Bool {
        true
    }
    
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidEnter session: UIDropSession
    ) {
        onSessionCallback?(true)
    }
    
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidExit session: UIDropSession
    ) {
        onSessionCallback?(false)
    }
    
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidUpdate session: UIDropSession
    ) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }
    
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        performDrop session: UIDropSession
    ) {
        onPreparingDataCallback?()
        
        let providers = session.items.map { $0.itemProvider }
        Task {
            await process(itemProviders: providers)
        }
    }
}

private extension DropInteractionService {
    func process(itemProviders: [NSItemProvider]) async {
        var files: [FileResult] = []
        
        for itemProvider in itemProviders {
            guard let url = try? await helper.getUrl(for: itemProvider),
                  let file = try? helper.getFileResult(for: url)
            else {
                continue
            }
            
            files.append(file)
        }
        
        do {
            try helper.validateFiles(files)
            onPreparedDataCallback?(.success(files))
        } catch {
            onPreparedDataCallback?(.failure(error))
        }
    }
}
