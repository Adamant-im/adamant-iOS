//
//  TaskManager.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 18.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import Foundation

final class TaskManager {
    private var tasks = Set<Task<(), Never>>()
    
    func insert(_ task: Task<(), Never>) {
        tasks.insert(task)
    }
    
    deinit {
        tasks.forEach { $0.cancel() }
    }
}
