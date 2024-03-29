//
//  NetworkService.swift
//
//
//  Created by Stanislav Jelezoglo on 28.03.2024.
//

import Foundation
import CommonKit
import UIKit
import FilesNetworkManagerKit
import Combine

final class NetworkService {
    typealias UploadResult = (id: String, nonce: String, data: Data)

    private let adamantCore = NativeAdamantCore()
    private let networkFileManager = FilesNetworkManager()
    
    func downloadFile(
        id: String,
        storage: String,
        fileType: String?,
        senderPublicKey: String,
        recipientPrivateKey: String,
        nonce: String
    ) async throws -> Data {
        let encodedData = try await networkFileManager.downloadFile(id, type: storage)
        
        guard let decodedData = adamantCore.decodeData(
            encodedData,
            rawNonce: nonce,
            senderPublicKey: senderPublicKey,
            privateKey: recipientPrivateKey
        )
        else {
            throw FileValidationError.fileNotFound
        }
        
        return decodedData
    }
    
    func uploadFile(
        url: URL,
        recipientPublicKey: String,
        senderPrivateKey: String
    ) async throws -> UploadResult {
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        
        let data = try Data(contentsOf: url)
        
        let encodedResult = adamantCore.encodeData(
            data,
            recipientPublicKey: recipientPublicKey,
            privateKey: senderPrivateKey
        )
        
        guard let encodedData = encodedResult?.data,
              let nonce = encodedResult?.nonce
        else {
            throw FileManagerError.cantEnctryptFile
        }
        
        let id = try await networkFileManager.uploadFiles(encodedData, type: .uploadCareApi)
        
        return (id: id, nonce: nonce, data: data)
    }
}

func makePublisher<Output>(
    operation: @escaping () async -> Output
) -> some Publisher<Output, Never> {
    Future { promise in
        Task {
            let output = await operation()
            promise(.success(output))
        }
    }
}

actor TaskQueue<Value> {
    private struct Effect {
        private let f: () -> AnyPublisher<Value, Never>
        let continuation: CheckedContinuation<Value, Never>
        
        init(
            operation: @escaping () async -> Value,
            continuation: CheckedContinuation<Value, Never>
        ) {
            self.f = { makePublisher(operation: operation).eraseToAnyPublisher() }
            self.continuation = continuation
        }
        
        func invoke() -> AnyPublisher<Value, Never> {
            f()
        }
    }
    
    typealias Operation = () async -> Value
    typealias Continuation = CheckedContinuation<Value, Never>
    
    private var cancellable: AnyCancellable!
    private var input = PassthroughSubject<Effect, Never>()
    
    init(maxTasks: Int = 1, bufferSize: Int = 100) {
        self.cancellable = input
            .buffer(size: bufferSize, prefetch: .keepFull, whenFull: .dropOldest)
            .flatMap(maxPublishers: .max(maxTasks)) { effect in
                effect.invoke().map { [continuation = effect.continuation] in ($0, continuation) }
            }
            .sink { value, continuation in
                continuation.resume(returning: value)
            }
    }
    
    func enqueue(_ operation: @escaping Operation) async -> Value {
        await withCheckedContinuation { continuation in
            self.send(operation: operation, continuation: continuation)
        }
    }
    
    private func send(operation: @escaping Operation, continuation: Continuation) {
        self.input.send(
            Effect(
                operation: operation,
                continuation: continuation
            )
        )
    }
}
