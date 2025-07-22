//
//  AppStateManager.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

@MainActor
class AppStateManager: ObservableObject {
    @Published var wallet: Wallet = Wallet()
    @Published var currentSession: TimerSession?
    @Published var weeklyUsage: WeeklyUsage = WeeklyUsage()
    @Published var settings: AppSettings = AppSettings()
    @Published var selectedTokens: Int = 0
    @Published var scheduledTokens: [ScheduledToken] = []
    
    // Toast notifications
    let toastManager = ToastManager()
    
    // MARK: - Services
    private let persistenceService = PersistenceService()
    private let timerService = TimerService()
    private let notificationService = NotificationService()
    private let scheduledTokenService = ScheduledTokenService()
    private let sessionRecommendationService = SessionRecommendationService()
    
    init() {
        setupServices()
        loadData()
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        // Set up timer service delegate
        timerService.delegate = self
        
        // Set up scheduled token service delegate
        scheduledTokenService.delegate = self
        
        // Bind timer service's current session to our published property
        timerService.$currentSession
            .assign(to: &$currentSession)
        
        // Bind scheduled token service's tokens to our published property
        scheduledTokenService.$scheduledTokens
            .assign(to: &$scheduledTokens)
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        wallet = persistenceService.loadWallet()
        currentSession = persistenceService.loadCurrentSession()
        weeklyUsage = persistenceService.loadWeeklyUsage()
        settings = persistenceService.loadSettings()
        
        let loadedScheduledTokens = persistenceService.loadScheduledTokens()
        scheduledTokenService.setScheduledTokens(loadedScheduledTokens)
        
        // Set timer service's current session
        timerService.currentSession = currentSession
        
        // Process any due scheduled tokens
        scheduledTokenService.processScheduledTokens()
    }
    
    private func saveData() {
        persistenceService.saveAllData(
            wallet: wallet,
            session: currentSession,
            usage: weeklyUsage,
            settings: settings,
            scheduledTokens: scheduledTokens
        )
    }
    
    // MARK: - Scheduled Token Management
    
    func addScheduledToken(_ scheduledToken: ScheduledToken) {
        scheduledTokenService.addScheduledToken(scheduledToken)
    }
    
    func updateScheduledToken(_ scheduledToken: ScheduledToken) {
        scheduledTokenService.updateScheduledToken(scheduledToken)
    }
    
    func removeScheduledToken(_ id: UUID) {
        scheduledTokenService.removeScheduledToken(id)
    }
    
    func toggleScheduledToken(_ id: UUID) {
        scheduledTokenService.toggleScheduledToken(id)
    }
    
    // MARK: - Timer Management
    
    func startTimer() {
        guard wallet.canRedeem(selectedTokens) else { 
            toastManager.show("Not enough tokens!", type: .error)
            return 
        }
        if wallet.redeemTokens(selectedTokens) {
            _ = timerService.startTimer(with: selectedTokens)
            toastManager.show("Timer started! Enjoy your leisure time.", type: .success)
            selectedTokens = 0
            saveData()
        }
    }
    
    func endTimerEarly() {
        let result = timerService.endTimerEarly(gracePeriodMinutes: settings.gracePeriodMinutes)
        
        // Add returned tokens back to wallet
        wallet.addTokens(result.returnedTokens)
        
        // Record redeemed time as usage (only if not in grace period)
        if result.redeemedTokens > 0 {
            weeklyUsage.addUsage(minutes: result.redeemedTokens * Token.minutesPerToken)
        }
        
        if result.returnedTokens > 0 {
            toastManager.show("\(result.returnedTokens) token\(result.returnedTokens > 1 ? "s" : "") returned", type: .success)
        } else {
            toastManager.show("Timer ended", type: .info)
        }
        
        saveData()
    }
    
    func pauseTimer() {
        timerService.pauseTimer()
        toastManager.show("Timer paused", type: .warning)
    }
    
    func resumeTimer() {
        timerService.resumeTimer()
        toastManager.show("Timer resumed", type: .info)
    }
    
    func fastForwardTimer() {
        timerService.fastForwardTimer()
    }
    
    func recordUserActivity() {
        timerService.recordUserActivity()
    }
    
    // MARK: - Public Methods
    
    func addTokensToWallet(_ count: Int) {
        wallet.addTokens(count)
        saveData()
        toastManager.show("\(count) token\(count > 1 ? "s" : "") added!", type: .success)
    }
    
    func addTokensToWalletUpToMax(_ count: Int) -> Int {
        let actualTokensAdded = wallet.addTokensUpToMax(count, maxTokens: settings.maxTokensInWallet)
        saveData()
        return actualTokensAdded
    }
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveData()
    }
    
    func updateWallet(_ newWallet: Wallet) {
        wallet = newWallet
        saveData()
    }
    
    // MARK: - Session Recommendations
    
    func getSessionRecommendations() -> [SessionRecommendation] {
        return sessionRecommendationService.getSessionRecommendations(
            weeklyUsage: weeklyUsage,
            settings: settings
        )
    }
    
    // MARK: - Formatting Utilities
    
    func formatTotalTime(minutes: Int) -> String {
        switch settings.timeDisplayFormat {
        case .minutesOnly:
            return "\(minutes) minutes"
        case .hoursMinutes:
            let hours = minutes / 60
            let mins = minutes % 60
            if hours > 0 {
                return "\(hours)h \(mins)m"
            } else {
                return "\(mins)m"
            }
        }
    }
    
    func formatTimerCountdown(totalSeconds: Int) -> String {
        let safeSeconds = max(0, totalSeconds)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let seconds = safeSeconds % 60
        
        switch settings.timeDisplayFormat {
        case .minutesOnly:
            let totalMinutes = safeSeconds / 60
            let remainingSeconds = safeSeconds % 60
            return String(format: "%d:%02d", totalMinutes, remainingSeconds)
        case .hoursMinutes:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
    
    func formatTimerDisplay(seconds: Int) -> String {
        let safeSeconds = max(0, seconds)
        let hours = safeSeconds / 3600
        let minutes = (safeSeconds % 3600) / 60
        let secs = safeSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Goal Tracking
    
    func todayUsageMinutes() -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayKey = formatter.string(from: Date())
        return weeklyUsage.dailyMinutes[dayKey, default: 0]
    }
    
    func dailyGoalProgress() -> Double {
        guard settings.dailyGoalMinutes > 0 else { return 0.0 }
        let todayUsage = todayUsageMinutes()
        return min(1.0, Double(todayUsage) / Double(settings.dailyGoalMinutes))
    }
    
    func weeklyGoalProgress() -> Double {
        guard settings.weeklyGoalMinutes > 0 else { return 0.0 }
        let weeklyUsage = weeklyUsage.totalMinutesThisWeek
        return min(1.0, Double(weeklyUsage) / Double(settings.weeklyGoalMinutes))
    }
    
    func monthlyGoalProgress() -> Double {
        guard settings.monthlyGoalMinutes > 0 else { return 0.0 }
        let monthlyUsage = monthlyUsageMinutes()
        return min(1.0, Double(monthlyUsage) / Double(settings.monthlyGoalMinutes))
    }
    
    func monthlyUsageMinutes() -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var total = 0
        var currentDate = monthStart
        while calendar.component(.month, from: currentDate) == calendar.component(.month, from: now) {
            let key = formatter.string(from: currentDate)
            total += weeklyUsage.dailyMinutes[key, default: 0]
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? now
        }
        return total
    }
    
    // MARK: - Debug Methods
    
    func resetWallet() {
        wallet = Wallet()
        selectedTokens = 0
        saveData()
    }
    
    func resetStats() {
        weeklyUsage = WeeklyUsage()
        saveData()
    }
}

// MARK: - Timer Service Delegate

extension AppStateManager: TimerServiceDelegate {
    func timerDidStart(session: TimerSession) {
        notificationService.scheduleNotifications(for: session)
    }
    
    func timerDidPause(session: TimerSession) {
        notificationService.cancelNotifications()
    }
    
    func timerDidResume(session: TimerSession) {
        notificationService.scheduleNotifications(for: session)
    }
    
    func timerDidComplete(session: TimerSession) {
        // Record completed session
        let sessionRecord = SessionRecord(
            startTime: session.startTime,
            endTime: Date(),
            originalTokens: session.originalTokens,
            actualMinutes: session.originalTokens * Token.minutesPerToken,
            wasCompleted: true,
            wasInGracePeriod: false
        )
        weeklyUsage.addSession(sessionRecord)
        weeklyUsage.addUsage(minutes: session.originalTokens * Token.minutesPerToken)
        
        toastManager.show("🎉 Timer completed! Great job!", type: .success)
        
        saveData()
        notificationService.cancelNotifications()
    }
    
    func timerDidEndEarly(session: TimerSession, returnedTokens: Int, redeemedTokens: Int) {
        // Record session
        let sessionRecord = SessionRecord(
            startTime: session.startTime,
            endTime: Date(),
            originalTokens: session.originalTokens,
            actualMinutes: redeemedTokens * Token.minutesPerToken,
            wasCompleted: false,
            wasInGracePeriod: session.isInGracePeriod(gracePeriodMinutes: settings.gracePeriodMinutes)
        )
        weeklyUsage.addSession(sessionRecord)
        
        notificationService.cancelNotifications()
    }
    
    func timerDidUpdate(session: TimerSession) {
        saveData()
    }
    
    func shouldProcessScheduledTokens() {
        scheduledTokenService.processScheduledTokens()
    }
    
    func shouldSaveData() {
        saveData()
    }
    
    func isAutoPauseEnabled() -> Bool {
        return settings.isAutoPauseEnabled
    }
    
    func getAutoPauseMinutes() -> Int {
        return settings.autoPauseMinutes
    }
}

// MARK: - Scheduled Token Service Delegate

extension AppStateManager: ScheduledTokenServiceDelegate {
    // Uses the existing addTokensToWallet method from the main class
    
    func getCurrentWalletTokens() -> Int {
        return wallet.totalTokens
    }
    
    func shouldSaveScheduledTokens() {
        saveData()
    }
}
