//
//  TaskManager.swift
//  CommonKit
//
//  Created by Dmitrij Meidus on 23.04.25.
//

public final class TaskManager {
    private var tasks = Set<Task<Void, Never>>()
    
    public init() {}

    public func insert(_ task: Task<(), Never>) {
        tasks.insert(task)
    }

    public func clean() {
        tasks.forEach { $0.cancel() }
    }

    deinit {
        clean()
    }
}

public extension Task where Success == Void, Failure == Never {
    func stored(in taskManager: TaskManager) {
        taskManager.insert(self)
    }
}
