//
//  AdamantApi+AdamantApiTask.swift
//  CommonKit
//
//  Created by Sergei Veretennikov on 04.03.2025.
//

import Foundation

final class AdamantApiTask<Output>: CancellableTask {
    private var task: Task<Result<Output, ApiServiceError>, Never>!
    private let id: UUID

    var isCancelled: Bool {
        cancelled
    }

    var value: Result<Output, ApiServiceError> {
        get async {
            await task.value
        }
    }

    init(id: UUID) {
        self.id = id
    }

    /// Must be called before `await` on `value`.
    func startTask(_ task: Task<Result<Output, ApiServiceError>, Never>) {
        self.task = task
    }

    func cancel() {
        self.cancelled = true
        task.cancel()
    }
}

protocol CancellableTask {
    var isCancelled: Bool { get }
    func cancel()
}
