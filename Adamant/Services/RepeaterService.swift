//
//  RepeaterService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import CommonKit

final class RepeaterService {
    private class Client: @unchecked Sendable {
        let interval: TimeInterval
        let queue: DispatchQueue?
        var timer: Timer?
        let callback: @Sendable () -> Void
        
        init(interval: TimeInterval, queue: DispatchQueue?, callback: @escaping @Sendable () -> Void) {
            self.interval = interval
            self.queue = queue
            self.callback = callback
        }
    }
    
    // MARK: Properties
    @Atomic private var foregroundTimers = [String: Client]()
    @Atomic private(set) var isPaused = false
    
    private let pauseLock = NSLock()
    
    deinit {
//        DispatchQueue.main.async {
//            for (_, timer) in foregroundTimers {
//                timer.invalidate()
//            }
//        }
    }
    
    /// Register a function to call each seconds on specified queue.
    ///
    /// - Parameters:
    ///      - label: unique identifier. You can use it to cancel calls.
    ///   - interval: Time interval (in seconds)
    ///   - queue: Queue for call. Default is main
    ///   - call: function to call
    func registerForegroundCall(label: String, interval: TimeInterval, queue: DispatchQueue?, callback: @escaping @Sendable () -> Void) {
        let client = Client(interval: interval, queue: queue, callback: callback)
        
        if let t = foregroundTimers[label]?.timer {
            t.invalidate()
        }
        
        foregroundTimers[label] = client
        
        // Start timer
        pauseLock.lock()
        defer { pauseLock.unlock() }
        
        if !isPaused {
            let timer = Timer(timeInterval: interval, target: self, selector: #selector(timerFired), userInfo: client, repeats: true)
            client.timer = timer
            
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func unregisterForegroundCall(label: String) {
        if let client = foregroundTimers[label] {
            client.timer?.invalidate()
            foregroundTimers.removeValue(forKey: label)
        }
    }
    
    func pauseAll() {
        pauseLock.lock()
        defer { pauseLock.unlock() }
        
        if isPaused {
            return
        }
        
        for (_, client) in self.foregroundTimers {
            client.timer?.invalidate()
            client.timer = nil
        }
        
        isPaused = true
    }
    
    func resumeAll() {
        pauseLock.lock()
        defer { pauseLock.unlock() }
        
        if !isPaused {
            return
        }
        
        for (_, client) in self.foregroundTimers {
            let timer = Timer(timeInterval: client.interval, target: self, selector: #selector(timerFired), userInfo: client, repeats: true)
            client.timer = timer
            
            RunLoop.main.add(timer, forMode: .common)
        }
        
        isPaused = false
    }
    
    @objc private func timerFired(timer: Timer) {
        if let client = timer.userInfo as? Client {
            let queue = client.queue ?? DispatchQueue.main
            queue.async {
                client.callback()
            }
        }
    }
}
