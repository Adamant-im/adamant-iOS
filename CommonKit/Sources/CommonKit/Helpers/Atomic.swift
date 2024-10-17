//
//  Atomic.swift
//  
//
//  Created by Andrew on 21.08.2023.
//

import Foundation

/// This property wrapper offers a locking mechanism for accessing/mutating values in a safer
/// way. Bear in mind that operations such as `+=` or executions of `if let` to read and then
/// mutate  values are *unsafe*.  Each time you access the variable to read it, it acquires the lock,
/// then once the read is finished it releases it. The following operation is to mutate the value, which
/// requires the lock to be mechanism again, however, another thread may have already claimed the lock
/// in between these two operations and have potentially changed the value. This may cause unexpected
/// results or crashes.
/// In order to ensure you've acquired the lock for a certain amount of time use the `mutate` method.
@propertyWrapper
public final class Atomic<Value>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()
    
    public var projectedValue: Atomic<Value> { self }
    
    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }
    
    public var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
    
    public init(_ value: Value) {
        _value = value
    }
    
    public convenience init(wrappedValue: Value) {
        self.init(wrappedValue)
    }

    /// Synchronises mutation to ensure the value doesn't get changed by another thread during this mutation.
    /// This method returns a value specified in the `mutation` closure.
    @discardableResult
    public func mutate<T>(_ mutation: (inout Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return mutation(&_value)
    }
    
    @discardableResult
    public func isolated<T>(_ processing: (Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return processing(_value)
    }
}

/*
 DispatchQueue.concurrentPerform(iterations: 100000) { (i) in
     // This code will crash on heavy concurrence usage,
     // because the `else if` checks if the array is empty
     // to then delete an object. However by the time it gets
     // to delete the object the value may have been changed
     // by another thread.
     //
     // if i % 2 == 0 {
     //      self.atomicArray.append(i)
     // } else if !self.atomicArray.isEmpty {
     //      self.atomicArray.removeLast()
     // }

     if i % 2 == 0 {
         self.atomicArray.append(i)
     } else {
         // Access the wrapper in order to synchronise the mutation
         // to ensure the value doesn't get changed by another thread
         // during this mutation.
         self._atomicArray.mutate {
             if !$0.isEmpty {
                 $0.removeLast()
             }
         }
     }
 }
*/
