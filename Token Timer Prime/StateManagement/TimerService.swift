//
//  TimerService.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import Foundation
import Combine

@MainActor
class TimerService: ObservableObject {
    @Published var currentSession: TimerSession?
    
    private var timer: Timer?
    private var backgroundTimer: Timer?
    private var lastActiveTime: Date = Date()
    
    weak var delegate: TimerServiceDelegate?
    
    init() {
        startBackgroundTimer()
        startInactivityMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        backgroundTimer?.invalidate()
    }
    
    // MARK: - Timer Management
    
    func startTimer(with tokens: Int) -> Bool {
        currentSession = TimerSession(tokens: tokens)
        delegate?.timerDidStart(session: currentSession!)
        return true
    }
    
    func pauseTimer() {
        guard var session = currentSession, !session.isPaused else { return }
        
        session.isPaused = true
        session.pausedTime = Date()
        currentSession = session
        delegate?.timerDidPause(session: session)
    }
    
    func resumeTimer() {
        guard var session = currentSession, session.isPaused else { return }
        
        if let pausedTime = session.pausedTime {
            session.totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        session.isPaused = false
        session.pausedTime = nil
        currentSession = session
        delegate?.timerDidResume(session: session)
    }
    
    func endTimerEarly(gracePeriodMinutes: Int) -> (returnedTokens: Int, redeemedTokens: Int) {
        guard let session = currentSession else { return (0, 0) }
        
        let result = session.tokensToReturnIfEndedEarly(gracePeriodMinutes: gracePeriodMinutes)
        
        // Clear current session
        currentSession = nil
        delegate?.timerDidEndEarly(session: session, returnedTokens: result.returnedTokens, redeemedTokens: result.redeemedTokens)
        
        return result
    }
    
    func fastForwardTimer() {
        guard var session = currentSession else { return }
        
        // Set the timer to end in 5 seconds
        let totalDurationInSeconds = TimeInterval(session.totalMinutes * 60)
        let desiredEndTime = Date().addingTimeInterval(5)
        
        let newTotalPausedDuration = desiredEndTime.timeIntervalSince(session.startTime) - totalDurationInSeconds
        session.totalPausedDuration = newTotalPausedDuration
        
        currentSession = session
        updateTimerState()
        delegate?.timerDidUpdate(session: session)
    }
    
    func recordUserActivity() {
        lastActiveTime = Date()
    }
    
    // MARK: - Private Methods
    
    private func startBackgroundTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateTimerState()
                
                // Check for scheduled tokens every minute
                if Int(Date().timeIntervalSince1970) % 60 == 0 {
                    self.delegate?.shouldProcessScheduledTokens()
                }
            }
        }
    }
    
    private func updateTimerState() {
        guard let session = currentSession else { return }
        
        // Check if session is completed first
        if !session.isPaused && session.isActive {
            let remaining = session.endTime.timeIntervalSince(Date())
            if remaining <= 0 {
                completeSession()
                return
            }
        }
        
        // Only update if not paused and not completed
        if !session.isPaused && session.isActive && !session.isCompleted {
            // Force refresh the remaining time calculation
            let _ = session.remainingMinutes
            currentSession = session
            
            // Auto-save every minute for better persistence
            if Int(Date().timeIntervalSince1970) % 60 == 0 {
                delegate?.shouldSaveData()
            }
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    private func completeSession() {
        guard let session = currentSession else { return }
        
        // Clear the session immediately
        currentSession = nil
        delegate?.timerDidComplete(session: session)
        
        // Force UI update
        objectWillChange.send()
    }
    
    private func startInactivityMonitoring() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForInactivity()
            }
        }
    }
    
    private func checkForInactivity() {
        guard let autoPauseEnabled = delegate?.isAutoPauseEnabled(),
              let autoPauseMinutes = delegate?.getAutoPauseMinutes(),
              autoPauseEnabled,
              let session = currentSession,
              !session.isPaused,
              session.isActive else { return }
        
        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        let autoPauseThreshold = TimeInterval(autoPauseMinutes * 60)
        
        if inactiveDuration >= autoPauseThreshold {
            pauseTimer()
        }
    }
}

// MARK: - Timer Service Delegate

@MainActor
protocol TimerServiceDelegate: AnyObject {
    func timerDidStart(session: TimerSession)
    func timerDidPause(session: TimerSession)
    func timerDidResume(session: TimerSession)
    func timerDidComplete(session: TimerSession)
    func timerDidEndEarly(session: TimerSession, returnedTokens: Int, redeemedTokens: Int)
    func timerDidUpdate(session: TimerSession)
    func shouldProcessScheduledTokens()
    func shouldSaveData()
    func isAutoPauseEnabled() -> Bool
    func getAutoPauseMinutes() -> Int
}
