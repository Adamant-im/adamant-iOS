//
//  DataProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum StateEnum {
    case empty
    case updating
    case upToDate
    case failedToUpdate(Error)
}

protocol DataProvider: AnyObject, Actor {
    var state: StateEnum { get }
    var stateObserver: AnyObservable<StateEnum> { get }
    var isInitiallySynced: Bool { get }
    
    func reload() async
    func reset()
}

// MARK: - Status Equatable
extension StateEnum: Equatable {
    
    /// Simple equatable function. Does not checks associated values.
    static func ==(lhs: StateEnum, rhs: StateEnum) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty): return true
        case (.updating, .updating): return true
        case (.upToDate, .upToDate): return true
        
        case (.failedToUpdate, .failedToUpdate): return true
            
        default: return false
        }
    }
}
