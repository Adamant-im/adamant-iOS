//
//  Deadline.swift
//  CommonKit
//
//  Created by Christian Benua on 06.02.2025.
//

import Foundation
import QuartzCore

public func deadline<R>(
    until instant: TimeInterval,
    isolation: isolated (any Actor)? = #isolation,
    operation: @Sendable () async throws -> R
) async throws -> R where R: Sendable {
    let result = await withoutActuallyEscaping(operation) { operation in
        await withTaskGroup(
            of: DeadlineState<R>.self,
            returning: Result<R, any Error>.self,
            isolation: isolation
        ) { taskGroup in
            
            taskGroup.addTask {
                do {
                    let result = try await operation()
                    return .operationResult(.success(result))
                } catch {
                    return .operationResult(.failure(error))
                }
            }
            
            taskGroup.addTask {
                do {
                    let interval = instant - CACurrentMediaTime()
                    guard interval > 0 else {
                        return .sleepResult(.failure(DeadlineExceededError()))
                    }
                    try await Task.sleep(interval: interval)
                    return .sleepResult(.success(false))
                } catch where Task.isCancelled {
                    return .sleepResult(.success(true))
                } catch {
                    return .sleepResult(.failure(error))
                }
            }
            
            defer {
                taskGroup.cancelAll()
            }
            
            for await next in taskGroup {
                switch next {
                case .operationResult(let result):
                    return result
                case .sleepResult(.success(false)):
                    return .failure(DeadlineExceededError())
                case .sleepResult(.success(true)):
                    continue
                case .sleepResult(.failure(let error)):
                    return .failure(error)
                }
            }
            
            preconditionFailure("Invalid state")
        }
    }
    
    return try result.get()
}

enum DeadlineState<T>: Sendable where T: Sendable {
    case operationResult(Result<T, Error>)
    case sleepResult(Result<Bool, Error>)
}

public struct DeadlineExceededError: Error {}
