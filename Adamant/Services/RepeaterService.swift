//
//  RepeaterService.swift
//  Adamant
//
//  Created by Anokhov Pavel on 09.02.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation

class RepeaterService {
	private class Client {
		let interval: TimeInterval
		let queue: DispatchQueue?
		weak var timer: Timer? = nil
		let callback: () -> Void
		
		init(interval: TimeInterval, queue: DispatchQueue?, callback: @escaping () -> Void) {
			self.interval = interval
			self.queue = queue
			self.callback = callback
		}
	}
	
	// MARK: Properties
	private var foregroundTimers = [String:Client]()
	private(set) var isPaused = false
	private let pauseSemaphore = DispatchSemaphore(value: 1)
	
	deinit {
//		DispatchQueue.main.async {
//			for (_, timer) in foregroundTimers {
//				timer.invalidate()
//			}
//		}
	}
	
	/// Register a function to call each seconds on specified queue.
	///
	/// - Parameters:
	///	  - label: unique identifier. You can use it to cancel calls.
	///   - interval: Time interval (in seconds)
	///   - queue: Queue for call. Default is main
	///   - call: function to call
	func registerForegroundCall(label: String, interval: TimeInterval, queue: DispatchQueue?, callback: @escaping () -> Void) {
		let client = Client(interval: interval, queue: queue, callback: callback)
		let timer = Timer(timeInterval: interval, target: self, selector: #selector(timerFired), userInfo: client, repeats: true)
		client.timer = timer
		
		if let t = foregroundTimers[label]?.timer {
			t.invalidate()
		}
		
		foregroundTimers[label] = client
		
		DispatchQueue.main.async {
			RunLoop.current.add(timer, forMode: .commonModes)
		}
	}
	
	func unregisterForegroundCall(label: String) {
		if let client = foregroundTimers[label] {
			client.timer?.invalidate()
			foregroundTimers.removeValue(forKey: label)
		}
	}
	
	func pauseAll() {
		pauseSemaphore.wait()
		
		defer {
			pauseSemaphore.signal()
		}
		
		if isPaused {
			return
		}
		
		DispatchQueue.main.async {
			for (_, client) in self.foregroundTimers {
				client.timer?.invalidate()
				client.timer = nil
			}
		}
		
		isPaused = true
	}
	
	func resumeAll() {
		pauseSemaphore.wait()
		
		defer {
			pauseSemaphore.signal()
		}
		
		if !isPaused {
			return
		}
		
		DispatchQueue.main.async {
			for (_, client) in self.foregroundTimers {
				let timer = Timer(timeInterval: client.interval, target: self, selector: #selector(self.timerFired), userInfo: client, repeats: true)
				
				RunLoop.current.add(timer, forMode: .commonModes)
			}
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
