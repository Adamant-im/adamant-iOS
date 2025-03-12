//
//  AdamantApi+AdamantApiTask.swift
//  CommonKit
//
//  Created by Sergei Veretennikov on 04.03.2025.
//

import Foundation

final class AdamantApiTask<Output>: CancellableTask {
    private let task: Task<Result<Output, ApiServiceError>, Never>
    private let id = UUID()
    var value: Result<Output, ApiServiceError> {
        get async {
            await task.value
        }
    }
    
    init(task: Task<Result<Output, ApiServiceError>, Never>) {
        self.task = task
    }
    
    func cancel() {
        task.cancel()
    }
    
    func storeIn(taskStorage: inout [UUID: CancellableTask]) {
        taskStorage[id] = self
    }
    
    func removeFrom(taskStorage: inout [UUID: CancellableTask]) {
        taskStorage[id] = nil
    }
}

protocol CancellableTask {
    func cancel()
}
