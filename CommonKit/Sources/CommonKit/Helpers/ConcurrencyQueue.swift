//
//  ConcurrencyQueue.swift
//
//
//  Created by Andrew G on 24.08.2024.
//

import Foundation

public actor ConcurrencyQueue<Output> {
    private var inputCounter: Int = .zero
    private var outputCounter: Int = .zero
    private var queue: [Int: () -> Void] = .init()
    
    public func perform(action: @escaping () async -> Output) async -> Output {
        inputCounter += 1
        let id = inputCounter
        let result = await action()
        
        return await withTaskCancellationHandler(
            operation: {
                await withCheckedContinuation { continuation in
                    enqueue(id: id) { continuation.resume(returning: result) }
                }
            },
            onCancel: {
                Task { await enqueue(id: id, action: {}) }
            }
        )
    }
    
    public init() {}
}

private extension ConcurrencyQueue {
    func enqueue(id: Int, action: @escaping () -> Void) {
        guard id == outputCounter + 1 else { return queue[id] = action }
        action()
        outputCounter += 1
        
        while let action = queue.removeValue(forKey: outputCounter + 1) {
            action()
            outputCounter += 1
        }
    }
}
