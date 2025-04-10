//
//  AdamantApi+AdamantApiTask.swift
//  CommonKit
//
//  Created by Sergei Veretennikov on 04.03.2025.
//

import Foundation

final class AdamantApiTask<Output>: CancellableTask {
    private let task: Task<Result<Output, ApiServiceError>, Never>
    private let id: UUID
    
    var isCancelled: Bool {
        task.isCancelled
    }
    
    var value: Result<Output, ApiServiceError> {
        get async {
            let value = await task.value
            if task.isCancelled {
                return .failure(ApiServiceError.requestCancelled)
            }
            return value
        }
    }

    init(task: Task<Result<Output, ApiServiceError>, Never>, id: UUID) {
        self.task = task
        self.id = id
    }

    func cancel() {
        task.cancel()
    }
}

protocol CancellableTask {
    var isCancelled: Bool { get }
    func cancel()
}
