//
//  DataProvider.swift
//  Adamant
//
//  Created by Anokhov Pavel on 29.01.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

enum DataProviderState {
    case empty
    case updating
    case upToDate
    case failedToUpdate(Error)
}

protocol DataProvider: AnyObject, Actor {
    var state: DataProviderState { get }
    var stateObserver: AnyObservable<DataProviderState> { get }
    var isInitiallySynced: Bool { get }
    
    func reload() async
    func reset()
}

// MARK: - Status Equatable
extension DataProviderState: Equatable {
    
    /// Simple equatable function. Does not checks associated values.
    static func ==(lhs: DataProviderState, rhs: DataProviderState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty): return true
        case (.updating, .updating): return true
        case (.upToDate, .upToDate): return true
        
        case (.failedToUpdate, .failedToUpdate): return true
            
        default: return false
        }
    }
}
