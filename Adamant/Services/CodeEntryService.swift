//
//  CodeEntryService.swift
//  Adamant
//
//  Created by Stanislav Jelezoglo on 15.08.2024.
//  Copyright © 2024 Adamant. All rights reserved.
//

import Combine
import UIKit

protocol CodeEntryProtocol {
    func attemptCodeEntry() -> Bool
    
    var remainingAttemptsPublisher: Published<Int>.Publisher {
        get
    }
    
    var remainingTimePublisher: Published<TimeInterval>.Publisher {
        get
    }
}

final class CodeEntryService: CodeEntryProtocol {
    private let maxAttempts: Int = 5
    private let stepInterval: TimeInterval = 1
    private var resetInterval: TimeInterval = 120
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published private var remainingAttempts: Int = 5
    @Published private var remainingTime: TimeInterval = 0
    
    var remainingAttemptsPublisher: Published<Int>.Publisher {
        $remainingAttempts
    }
    
    var remainingTimePublisher: Published<TimeInterval>.Publisher {
        $remainingTime
    }
    
    func attemptCodeEntry() -> Bool {
        guard remainingAttempts > .zero else { return false }
        
        remainingAttempts -= 1
        
        guard remainingAttempts <= 0 else {
            return true
        }
        
        startTimer()
        return false
    }
}

private extension CodeEntryService {
    func startTimer() {
        remainingTime = resetInterval
        timer = Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= stepInterval
            if self.remainingTime <= .zero {
                self.resetAttempts()
            }
        }
    }
    
    func resetAttempts() {
        remainingAttempts = maxAttempts
        remainingTime = .zero
        timer?.invalidate()
        timer = nil
    }
}
