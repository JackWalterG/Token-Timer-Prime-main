//
//  TimerSession.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

struct TimerSession: Codable {
    let id: UUID
    let originalTokens: Int
    let totalMinutes: Int
    let startTime: Date
    var isActive: Bool
    var isPaused: Bool
    var pausedTime: Date?
    var totalPausedDuration: TimeInterval
    
    init(id: UUID = UUID(), tokens: Int) {
        self.id = id
        self.originalTokens = tokens
        self.totalMinutes = tokens * Token.minutesPerToken
        self.startTime = Date()
        self.isActive = true
        self.isPaused = false
        self.pausedTime = nil
        self.totalPausedDuration = 0
    }
    
    var endTime: Date {
        return startTime.addingTimeInterval(TimeInterval(totalMinutes * 60) + totalPausedDuration)
    }
    
    var activeEndTime: Date {
        // End time if we resumed right now (excludes current pause duration)
        let currentPauseDuration = isPaused && pausedTime != nil ? Date().timeIntervalSince(pausedTime!) : 0
        return startTime.addingTimeInterval(TimeInterval(totalMinutes * 60) + totalPausedDuration + currentPauseDuration)
    }
    
    var remainingMinutes: Int {
        if isPaused { 
            // When paused, return the minutes component of the frozen time
            guard let pausedTime = pausedTime else { return 0 }
            let remainingAtPause = endTime.timeIntervalSince(pausedTime)
            return max(0, Int(remainingAtPause / 60))
        }
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        return max(0, Int(remaining / 60))
    }
    
    var remainingSeconds: Int {
        if isPaused { 
            // When paused, return the seconds component of the frozen time
            guard let pausedTime = pausedTime else { return 0 }
            let remainingAtPause = endTime.timeIntervalSince(pausedTime)
            return max(0, Int(remainingAtPause.truncatingRemainder(dividingBy: 60)))
        }
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        return max(0, Int(remaining.truncatingRemainder(dividingBy: 60)))
    }
    
    var totalRemainingSeconds: Int {
        if isPaused { 
            // When paused, freeze the timer at the value it had when paused
            // Calculate what the remaining time was at the moment of pause
            guard let pausedTime = pausedTime else { return 0 }
            let remainingAtPause = endTime.timeIntervalSince(pausedTime)
            return max(0, Int(remainingAtPause))
        }
        let now = Date()
        let remaining = endTime.timeIntervalSince(now)
        // Ensure we never show negative time - if timer is done, return 0
        return max(0, Int(remaining))
    }
    
    var isCompleted: Bool {
        if isPaused { return false }
        // Check if current time has passed the end time
        return Date() >= endTime
    }
    
    var isInGracePeriod: Bool {
        let effectiveElapsed = Date().timeIntervalSince(startTime) - totalPausedDuration - (isPaused && pausedTime != nil ? Date().timeIntervalSince(pausedTime!) : 0)
        return effectiveElapsed <= 120 // Will be made configurable via settings
    }
    
    func isInGracePeriod(gracePeriodMinutes: Int) -> Bool {
        let effectiveElapsed = Date().timeIntervalSince(startTime) - totalPausedDuration - (isPaused && pausedTime != nil ? Date().timeIntervalSince(pausedTime!) : 0)
        return effectiveElapsed <= TimeInterval(gracePeriodMinutes * 60)
    }
    
    // Calculate tokens to return when ending early
    func tokensToReturnIfEndedEarly() -> (returnedTokens: Int, redeemedTokens: Int) {
        // If in grace period (first 2 minutes), return ALL tokens
        if isInGracePeriod {
            return (returnedTokens: originalTokens, redeemedTokens: 0)
        }
        
        let remaining = remainingMinutes
        let fullTokensRemaining = remaining / Token.minutesPerToken
        let redeemedTokens = originalTokens - fullTokensRemaining
        return (returnedTokens: fullTokensRemaining, redeemedTokens: redeemedTokens)
    }
    
    func tokensToReturnIfEndedEarly(gracePeriodMinutes: Int) -> (returnedTokens: Int, redeemedTokens: Int) {
        // If in grace period, return ALL tokens
        if isInGracePeriod(gracePeriodMinutes: gracePeriodMinutes) {
            return (returnedTokens: originalTokens, redeemedTokens: 0)
        }
        
        let remaining = remainingMinutes
        let fullTokensRemaining = remaining / Token.minutesPerToken
        let redeemedTokens = originalTokens - fullTokensRemaining
        return (returnedTokens: fullTokensRemaining, redeemedTokens: redeemedTokens)
    }
}
