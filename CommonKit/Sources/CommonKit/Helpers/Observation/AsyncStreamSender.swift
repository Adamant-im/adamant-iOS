//
//  AsyncStreamSender.swift
//  CommonKit
//
//  Created by Andrew G on 17.10.2024.
//

public final class AsyncStreamSender<Element: Sendable>: Sendable {
    public let stream: AsyncStream<Element>
    private let continuation: AsyncStream<Element>.Continuation?
    
    public init() {
        var continuation: AsyncStream<Element>.Continuation?
        stream = .init { continuation = $0 }
        assert(continuation != nil)
        self.continuation = continuation
    }
    
    public func send(_ value: Element) {
        continuation?.yield(value)
    }
    
    public func finish() {
        continuation?.finish()
    }
}
