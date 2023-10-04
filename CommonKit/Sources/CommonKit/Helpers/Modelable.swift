//
//  Modelable.swift
//  
//
//  Created by Andrew G on 04.10.2023.
//

public protocol Modelable: AnyObject {
    associatedtype Model: Equatable
    
    var modelStorage: Model { get set }
}

public extension Modelable {
    var model: Model {
        get { modelStorage }
        set {
            guard modelStorage != newValue else { return }
            modelStorage = newValue
        }
    }
}
