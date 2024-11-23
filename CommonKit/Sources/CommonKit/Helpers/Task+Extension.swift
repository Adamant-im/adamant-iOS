//
//  Task+Extension.swift
//  Adamant
//
//  Created by Andrey Golubenko on 06.02.2023.
//  Copyright © 2023 Adamant. All rights reserved.
//

import UIKit
import Combine

public extension Task {
    func eraseToAnyCancellable() -> AnyCancellable {
        .init(cancel)
    }
    
    func store<C>(in collection: inout C) where C: RangeReplaceableCollection, C.Element == AnyCancellable {
        eraseToAnyCancellable().store(in: &collection)
    }

    func store(in set: inout Set<AnyCancellable>) {
        eraseToAnyCancellable().store(in: &set)
    }
}

public extension Task where Success == Never, Failure == Never {
    static func sleep(interval: TimeInterval, pauseInBackground: Bool = false) async throws {
        guard pauseInBackground else {
            return try await Task<Never, Never>.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
        
        let startDate = Date.now
        let counter = BackgroundTimeCounter()
        await counter.start()
        try await Task.sleep(interval: interval, pauseInBackground: false)
        let timeSpentInBackground = await counter.total ?? .zero
        await counter.stopAndReset()
        let endDate = Date.now
        let actualInterval = endDate.timeIntervalSince(startDate)
        let additionalInterval = timeSpentInBackground + interval - actualInterval
        
        guard additionalInterval > .zero else { return }
        try await Task.sleep(interval: additionalInterval, pauseInBackground: true)
    }
    
    /// Avoid using it. It lowers performance due to changing threads.
    @discardableResult
    static func sync<T: Sendable>(_ action: @Sendable @escaping () async -> T) -> T {
        _sync(action)
    }
}

@discardableResult
private func _sync<T: Sendable>(_ action: @Sendable @escaping () async -> T) -> T {
    var result: T?
    let semaphore = DispatchSemaphore(value: .zero)
    
    Task {
        result = await action()
        semaphore.signal()
    }
    
    semaphore.wait()
    return result!
}

private actor BackgroundTimeCounter {
    private var _total: TimeInterval = .zero
    private var subscriptions = Set<AnyCancellable>()
    private var backgroundEnteringDate: Date = .adamantNullDate
    private var isInBackground = false
    
    var total: TimeInterval? {
        guard !subscriptions.isEmpty else { return nil }
        
        return isInBackground
            ? _total + Date.now.timeIntervalSince(backgroundEnteringDate)
            : _total
    }
    
    func start() {
        Task {
            backgroundEnteringDate = .now
            isInBackground = await UIApplication.shared.applicationState == .background
            
            NotificationCenter.default
                .notifications(named: UIApplication.didBecomeActiveNotification)
                .sink { [weak self] _ in await self?.didBecomeActive() }
                .store(in: &subscriptions)
            
            NotificationCenter.default
                .notifications(named: UIApplication.didEnterBackgroundNotification)
                .sink { [weak self] _ in await self?.didEnterBeckground() }
                .store(in: &subscriptions)
        }
    }
    
    func stopAndReset() {
        _total = .zero
        subscriptions = .init()
        backgroundEnteringDate = .adamantNullDate
    }
    
    private func didEnterBeckground() {
        backgroundEnteringDate = .now
        isInBackground = true
    }
    
    private func didBecomeActive() {
        _total += Date.now.timeIntervalSince(backgroundEnteringDate)
        isInBackground = false
    }
}
