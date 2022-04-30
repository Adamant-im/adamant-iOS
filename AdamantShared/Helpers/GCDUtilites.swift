//
//  GCDUtilites.swift
//  Adamant
//
//  Created by Андрей on 29.04.2022.
//  Copyright © 2022 Adamant. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static func onMainSync(_ action: () -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync(execute: action)
            return
        }
        action()
    }
    
    static func onMainAsync(_ action: @escaping () -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async(execute: action)
            return
        }
        action()
    }
}
