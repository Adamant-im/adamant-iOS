//
//  AnyChatUpdatingNotificator.swift
//  Adamant
//
//  Created by Sergei Veretennikov on 15.04.2025.
//  Copyright © 2025 Adamant. All rights reserved.
//

import CommonKit
import Foundation

protocol AnyChatUpdatingNotificator {
    var needToShowChatUpdateSpinnerObserver: AnyObservable<Bool> { get }
    
    func updateLastUpdateTime()
    func startMonitoring()
    func stopMonitoring()
}

final class ChatUpdatingNotificator: AnyChatUpdatingNotificator {
    @ObservableValue private var needToShowChatUpdateSpinner: Bool = false
    private var lastUpdate: Date?
    private var continuation: AsyncThrowingStream<Bool, Error>.Continuation?
    private var dateOfLongAwait: Date? {
        lastUpdate?.addingTimeInterval(AppDelegate.Constants.updateChatsInterval + 3)
    }
    
    var needToShowChatUpdateSpinnerObserver: AnyObservable<Bool> { $needToShowChatUpdateSpinner.eraseToAnyPublisher() }
    
    init() {}
    
    func updateLastUpdateTime() {
        self.lastUpdate = .init()
        needToShowChatUpdateSpinner = false
    }
    
    func startMonitoring() {
        guard continuation == nil else { return }
        let stream = AsyncThrowingStream<Bool, Error> { continuation in
            self.continuation = continuation
        }
        
        Task {
            for try await bool in stream {
                if let dateOfLongAwait, dateOfLongAwait <= .now {
                    needToShowChatUpdateSpinner = dateOfLongAwait <= .now
                } else {
                    needToShowChatUpdateSpinner = false
                }
                
                try await Task.sleep(interval: 0.5)
                guard !Task.isCancelled else { return }
                self.continuation?.yield(true)
            }
        }
        self.continuation?.yield(true)
    }
    
    func stopMonitoring() {
        continuation?.finish()
        continuation = nil
        lastUpdate = nil
        needToShowChatUpdateSpinner = false
    }
}
