//
//  Models.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - Core Models

struct Token: Identifiable, Codable {
    let id: UUID
    static let minutesPerToken = 15

    init(id: UUID = UUID()) {
        self.id = id
    }
}

struct ScheduledToken: Identifiable, Codable {
    let id: UUID
    var tokenCount: Int
    var scheduledDate: Date
    var title: String
    var notes: String?
    var recurrenceType: RecurrenceType
    var isActive: Bool
    let createdDate: Date
    var maxWalletTokens: Int?
    
    init(id: UUID = UUID(), tokenCount: Int, scheduledDate: Date, title: String, notes: String? = nil, recurrenceType: RecurrenceType = .daily, isActive: Bool = true, createdDate: Date = Date(), maxWalletTokens: Int? = nil) {
        self.id = id
        self.tokenCount = tokenCount
        self.scheduledDate = scheduledDate
        self.title = title
        self.notes = notes
        self.recurrenceType = recurrenceType
        self.isActive = isActive
        self.createdDate = createdDate
        self.maxWalletTokens = maxWalletTokens
    }
    
    var nextOccurrence: Date? {
        guard isActive else { return nil }
        
        let now = Date()
        var nextDate = scheduledDate
        
        switch recurrenceType {
        case .daily:
            while nextDate <= now {
                nextDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
            return nextDate
        case .weekly:
            while nextDate <= now {
                nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            }
            return nextDate
        case .monthly:
            while nextDate <= now {
                nextDate = Calendar.current.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            }
            return nextDate
        }
    }
    
    var isPastDue: Bool {
        return false // Recurring events are never past due, they just move to next occurrence
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

struct Wallet: Codable {
    var totalTokens: Int
    
    init(totalTokens: Int = 0) {
        self.totalTokens = totalTokens
    }
    
    var availableTokens: Int {
        return totalTokens
    }
    
    mutating func addTokens(_ count: Int) {
        totalTokens += count
    }
    
    mutating func addTokensUpToMax(_ count: Int, maxTokens: Int) -> Int {
        guard maxTokens > 0 else {
            totalTokens += count
            return count
        }
        
        let tokensToAdd = min(count, maxTokens - totalTokens)
        let actualTokensAdded = max(0, tokensToAdd)
        totalTokens += actualTokensAdded
        return actualTokensAdded
    }
    
    mutating func redeemTokens(_ count: Int) -> Bool {
        guard totalTokens >= count else { return false }
        totalTokens -= count
        return true
    }
    
    func canRedeem(_ count: Int) -> Bool {
        return totalTokens >= count
    }
}

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

struct WeeklyUsage: Codable {
    fileprivate var dailyMinutes: [String: Int] = [:]
    var sessions: [SessionRecord] = []
    
    private var weekKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"
        return formatter.string(from: Date())
    }
    
    private var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    mutating func addUsage(minutes: Int) {
        let key = dayKey
        dailyMinutes[key, default: 0] += minutes
    }
    
    mutating func addSession(_ session: SessionRecord) {
        sessions.append(session)
        // Keep only last 100 sessions for performance
        if sessions.count > 100 {
            sessions = Array(sessions.suffix(100))
        }
    }
    
    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var total = 0
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let key = formatter.string(from: day)
                total += dailyMinutes[key, default: 0]
            }
        }
        return total
    }
    
    var totalHoursThisWeek: Double {
        return Double(totalMinutesThisWeek) / 60.0
    }
    
    // MARK: - Analytics
    
    var averageSessionLength: Int {
        let recentSessions = sessions.suffix(20) // Last 20 sessions
        guard !recentSessions.isEmpty else { return 0 }
        let total = recentSessions.reduce(0) { $0 + $1.actualMinutes }
        return total / recentSessions.count
    }
    
    var favoriteSessionLengths: [Int] {
        let sessionCounts = Dictionary(grouping: sessions.suffix(50)) { $0.originalTokens }
        return sessionCounts.sorted { $0.value.count > $1.value.count }
                           .prefix(3)
                           .map { $0.key }
    }
    
    func peakUsageHours() -> [Int] {
        let hourCounts = sessions.suffix(50).reduce(into: [Int: Int]()) { counts, session in
            let hour = Calendar.current.component(.hour, from: session.startTime)
            counts[hour, default: 0] += 1
        }
        return hourCounts.sorted { $0.value > $1.value }
                        .prefix(3)
                        .map { $0.key }
    }
}

struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let originalTokens: Int
    let actualMinutes: Int
    let wasCompleted: Bool
    let wasInGracePeriod: Bool

    init(id: UUID = UUID(), startTime: Date, endTime: Date, originalTokens: Int, actualMinutes: Int, wasCompleted: Bool, wasInGracePeriod: Bool) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.originalTokens = originalTokens
        self.actualMinutes = actualMinutes
        self.wasCompleted = wasCompleted
        self.wasInGracePeriod = wasInGracePeriod
    }
}

struct SessionRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let message: String
    let suggestedTokens: Int
    let reason: String
    
    enum RecommendationType {
        case timeOptimal
        case lengthBased
        case goalBased
        case streakBased
    }
}

struct AppSettings: Codable {
    var isPasscodeEnabled: Bool = false
    var passcode: String = ""
    var hasCompletedSetup: Bool = false
    var timeDisplayFormat: TimeDisplayFormat = .hoursMinutes
    var timerDisplayMode: TimerDisplayMode = .linear
    var gracePeriodMinutes: Int = 2
    var isDarkModeEnabled: Bool = false
    var hasCompletedOnboarding: Bool = false
    var isAutoPauseEnabled: Bool = true
    var autoPauseMinutes: Int = 10 // Auto-pause after 10 minutes of inactivity
    
    // Goal Settings
    var dailyGoalMinutes: Int = 0 // 0 means no goal
    var weeklyGoalMinutes: Int = 0 // 0 means no goal
    var monthlyGoalMinutes: Int = 0 // 0 means no goal
    
    // Wallet Settings
    var maxTokensInWallet: Int = 0 // 0 means no limit
    
    func validatePasscode(_ input: String) -> Bool {
        return !isPasscodeEnabled || input == passcode
    }
}

enum TimeDisplayFormat: String, Codable, CaseIterable {
    case minutesOnly = "minutesOnly"
    case hoursMinutes = "hoursMinutes"
    
    var displayName: String {
        switch self {
        case .minutesOnly:
            return "Minutes Only"
        case .hoursMinutes:
            return "Hours:Minutes"
        }
    }
}

enum TimerDisplayMode: String, Codable, CaseIterable {
    case linear = "linear"
    
    var displayName: String {
        switch self {
        case .linear:
            return "Linear Progress Bar"
        }
    }
}

// MARK: - App State Manager

@MainActor
class AppStateManager: ObservableObject {
    @Published var wallet: Wallet = Wallet()
    @Published var currentSession: TimerSession?
    @Published var weeklyUsage: WeeklyUsage = WeeklyUsage()
    @Published var settings: AppSettings = AppSettings()
    @Published var selectedTokens: Int = 0
    @Published var scheduledTokens: [ScheduledToken] = []
    
    // Live Activities Manager
    // @Published var liveActivitiesManager = LiveActivitiesManager() (removed)
    
    private let userDefaults = UserDefaults.standard
    private var timer: Timer?
    private var lastActiveTime: Date = Date()
    private var backgroundTimer: Timer?
    
    init() {
        loadData()
        startBackgroundTimer()
        startInactivityMonitoring()
    }
    
    deinit {
        timer?.invalidate()
        backgroundTimer?.invalidate()
    }
    
    // MARK: - Persistence
    
    private func loadData() {
        if let walletData = userDefaults.data(forKey: "wallet"),
           let wallet = try? JSONDecoder().decode(Wallet.self, from: walletData) {
            self.wallet = wallet
        }
        
        if let sessionData = userDefaults.data(forKey: "currentSession"),
           let session = try? JSONDecoder().decode(TimerSession.self, from: sessionData) {
            if session.isActive && !session.isCompleted {
                self.currentSession = session
            } else {
                // Session completed, record usage and clear
                var usage = weeklyUsage
                usage.addUsage(minutes: session.originalTokens * Token.minutesPerToken)
                self.weeklyUsage = usage
                userDefaults.removeObject(forKey: "currentSession")
            }
        }
        
        if let usageData = userDefaults.data(forKey: "weeklyUsage"),
           let usage = try? JSONDecoder().decode(WeeklyUsage.self, from: usageData) {
            self.weeklyUsage = usage
        }
        
        if let settingsData = userDefaults.data(forKey: "settings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: settingsData) {
            self.settings = settings
        }
        
        if let scheduledData = userDefaults.data(forKey: "scheduledTokens"),
           let scheduled = try? JSONDecoder().decode([ScheduledToken].self, from: scheduledData) {
            self.scheduledTokens = scheduled
        }
        
        // Process any due scheduled tokens
        processScheduledTokens()
    }
    
    private func saveData() {
        if let walletData = try? JSONEncoder().encode(wallet) {
            userDefaults.set(walletData, forKey: "wallet")
        }
        
        if let currentSession = currentSession,
           let sessionData = try? JSONEncoder().encode(currentSession) {
            userDefaults.set(sessionData, forKey: "currentSession")
        } else {
            userDefaults.removeObject(forKey: "currentSession")
        }
        
        if let usageData = try? JSONEncoder().encode(weeklyUsage) {
            userDefaults.set(usageData, forKey: "weeklyUsage")
        }
        
        if let settingsData = try? JSONEncoder().encode(settings) {
            userDefaults.set(settingsData, forKey: "settings")
        }
        
        if let scheduledData = try? JSONEncoder().encode(scheduledTokens) {
            userDefaults.set(scheduledData, forKey: "scheduledTokens")
        }
    }
    
    // MARK: - Scheduled Tokens
    
    private func processScheduledTokens() {
        var changed = false
        
        for i in 0..<scheduledTokens.count {
            var scheduled = scheduledTokens[i]
            guard scheduled.isActive else { continue }
            
            let nextOccurrenceDate = scheduled.scheduledDate
            var tokensToAddThisTime = 0

            var tempNextOccurrenceDate = nextOccurrenceDate
            while tempNextOccurrenceDate <= Date() {
                tokensToAddThisTime += scheduled.tokenCount
                
                let nextDate: Date?
                switch scheduled.recurrenceType {
                case .daily:
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: tempNextOccurrenceDate)
                case .weekly:
                    nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: tempNextOccurrenceDate)
                case .monthly:
                    nextDate = Calendar.current.date(byAdding: .month, value: 1, to: tempNextOccurrenceDate)
                }
                
                if let next = nextDate {
                    tempNextOccurrenceDate = next
                } else {
                    break
                }
            }
            
            if tokensToAddThisTime > 0 {
                scheduled.scheduledDate = tempNextOccurrenceDate
                changed = true
            }
            
            if tokensToAddThisTime > 0 {
                if let maxTokens = scheduled.maxWalletTokens {
                    let currentTokens = wallet.totalTokens
                    let canAdd = max(0, maxTokens - currentTokens)
                    let actualTokensToAdd = min(tokensToAddThisTime, canAdd)
                    if actualTokensToAdd > 0 {
                        wallet.addTokens(actualTokensToAdd)
                    }
                } else {
                    wallet.addTokens(tokensToAddThisTime)
                }
            }
            
            scheduledTokens[i] = scheduled
        }
        
        if changed {
            saveData()
        }
    }
    
    // MARK: - Scheduled Token Management
    
    func addScheduledToken(_ scheduledToken: ScheduledToken) {
        scheduledTokens.append(scheduledToken)
        saveData()
    }
    
    func updateScheduledToken(_ scheduledToken: ScheduledToken) {
        if let index = scheduledTokens.firstIndex(where: { $0.id == scheduledToken.id }) {
            scheduledTokens[index] = scheduledToken
            saveData()
        }
    }
    
    func removeScheduledToken(_ id: UUID) {
        scheduledTokens.removeAll { $0.id == id }
        saveData()
    }
    
    func toggleScheduledToken(_ id: UUID) {
        if let index = scheduledTokens.firstIndex(where: { $0.id == id }) {
            scheduledTokens[index].isActive.toggle()
            saveData()
        }
    }
    
    // MARK: - Timer Management
    
    private func startBackgroundTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.updateTimerState()
                // Perform cleanup every 10 minutes
                if Int(Date().timeIntervalSince1970) % 600 == 0 {
                    self.cleanup()
                }
                // Check for scheduled tokens every minute
                if Int(Date().timeIntervalSince1970) % 60 == 0 {
                    self.processScheduledTokens()
                }
            }
        }
    }
    
    private func updateTimerState() {
        guard let session = currentSession else { return }
        // Check if session is completed first, before any other updates
        if !session.isPaused && session.isActive {
            let remaining = session.endTime.timeIntervalSince(Date())
            if remaining <= 0 {
                completeSession()
                return // Exit early to prevent further updates
            }
        }
        // Only update if not paused and not completed
        if !session.isPaused && session.isActive && !session.isCompleted {
            // Force refresh the remaining time calculation
            let _ = session.remainingMinutes
            currentSession = session
            // Removed live activity updates
            // Auto-save every minute for better persistence
            if Int(Date().timeIntervalSince1970) % 60 == 0 {
                saveData()
            }
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    // MARK: - Public Methods
    
    func addTokensToWallet(_ count: Int) {
        wallet.addTokens(count)
        saveData()
    }
    
    func addTokensToWalletUpToMax(_ count: Int) -> Int {
        let actualTokensAdded = wallet.addTokensUpToMax(count, maxTokens: settings.maxTokensInWallet)
        saveData()
        return actualTokensAdded
    }
    
    func startTimer() {
        guard wallet.canRedeem(selectedTokens) else { return }
        if wallet.redeemTokens(selectedTokens) {
            currentSession = TimerSession(tokens: selectedTokens)
            selectedTokens = 0
            saveData()
            scheduleNotifications()
            // Removed live activity start
        }
    }
    
    func endTimerEarly() {
        guard let session = currentSession else { return }
        
        let (returnedTokens, redeemedTokens) = session.tokensToReturnIfEndedEarly(gracePeriodMinutes: settings.gracePeriodMinutes)
        
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
        
        // Add returned tokens back to wallet
        wallet.addTokens(returnedTokens)
        
        // Record redeemed time as usage (only if not in grace period)
        if redeemedTokens > 0 {
            weeklyUsage.addUsage(minutes: redeemedTokens * Token.minutesPerToken)
        }
        
        // Removed live activity end
        // Clear current session
        currentSession = nil
        saveData()
        cancelNotifications()
    }
    
    func pauseTimer() {
        guard var session = currentSession, !session.isPaused else { return }
        
        session.isPaused = true
        session.pausedTime = Date()
        currentSession = session
        // Removed live activity pause update
        saveData()
        cancelNotifications()
    }
    
    func resumeTimer() {
        guard var session = currentSession, session.isPaused else { return }
        
        if let pausedTime = session.pausedTime {
            session.totalPausedDuration += Date().timeIntervalSince(pausedTime)
        }
        session.isPaused = false
        session.pausedTime = nil
        currentSession = session
        // Removed live activity resume update
        saveData()
        scheduleNotifications()
    }
    
    private func completeSession() {
        guard let session = currentSession else { return }
        
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
        
        // Removed live activity completion
        // Clear the session immediately to prevent display issues
        currentSession = nil
        saveData()
        cancelNotifications()
        
        // Force UI update
        objectWillChange.send()
    }
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        saveData()
    }
    
    func updateWallet(_ newWallet: Wallet) {
        wallet = newWallet
        saveData()
    }
    
    // MARK: - Notifications
    
    private func scheduleNotifications() {
        guard let session = currentSession else { return }
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // Schedule notification for timer completion
        let content = UNMutableNotificationContent()
        content.title = "Leisure Time Complete"
        content.body = "Your \(session.originalTokens) token timer has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(session.remainingMinutes * 60),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer_complete",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        // Schedule periodic updates (every 5 minutes)
        schedulePeriodicNotifications()
    }
    
    private func schedulePeriodicNotifications() {
        guard let session = currentSession else { return }
        
        let center = UNUserNotificationCenter.current()
        let updateIntervals = [5, 10, 15, 30] // minutes
        
        for interval in updateIntervals {
            if session.remainingMinutes > interval {
                let content = UNMutableNotificationContent()
                content.title = "Leisure Time Remaining"
                let remaining = session.remainingMinutes - interval
                content.body = formatTimeRemaining(minutes: remaining)
                content.sound = nil // Silent update
                
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(interval * 60),
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "timer_update_\(interval)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request)
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func formatTimeRemaining(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m remaining"
        } else {
            return "\(mins)m remaining"
        }
    }
    
    // Format total time based on user preference
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
    
    // Format timer countdown with seconds
    func formatTimerCountdown(totalSeconds: Int) -> String {
        // Ensure we never display negative time
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
        // Ensure we never display negative time
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

    func fastForwardTimer() {
        guard var session = currentSession else { return }
        
        // We want the endTime to be 5 seconds from now.
        // The formula for endTime is: startTime + totalDuration + totalPausedDuration
        // So, we solve for the required totalPausedDuration:
        // Date() + 5 = session.startTime + totalDurationInSeconds + newTotalPausedDuration
        let totalDurationInSeconds = TimeInterval(session.totalMinutes * 60)
        let desiredEndTime = Date().addingTimeInterval(5)
        
        let newTotalPausedDuration = desiredEndTime.timeIntervalSince(session.startTime) - totalDurationInSeconds
        session.totalPausedDuration = newTotalPausedDuration
        
        currentSession = session
        updateTimerState()
        saveData()
    }
    
    // MARK: - Auto-Pause Functionality
    
    private func startInactivityMonitoring() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForInactivity()
            }
        }
    }
    
    private func checkForInactivity() {
        guard settings.isAutoPauseEnabled,
              let session = currentSession,
              !session.isPaused,
              session.isActive else { return }
        
        let inactiveDuration = Date().timeIntervalSince(lastActiveTime)
        let autoPauseThreshold = TimeInterval(settings.autoPauseMinutes * 60)
        
        if inactiveDuration >= autoPauseThreshold {
            pauseTimer()
            // Could add notification here if desired
        }
    }
    
    func recordUserActivity() {
        lastActiveTime = Date()
    }
    
    // MARK: - Session Recommendations
    
    func getSessionRecommendations() -> [SessionRecommendation] {
        var recommendations: [SessionRecommendation] = []
        
        // Analyze usage patterns
        let favoriteLength = weeklyUsage.favoriteSessionLengths.first ?? 2
        let avgLength = weeklyUsage.averageSessionLength
        let peakHours = weeklyUsage.peakUsageHours()
        
        // Time-based recommendations
        let currentHour = Calendar.current.component(.hour, from: Date())
        if peakHours.contains(currentHour) {
            recommendations.append(SessionRecommendation(
                type: .timeOptimal,
                message: "Peak usage time detected! Consider a longer session.",
                suggestedTokens: max(favoriteLength, 3),
                reason: "Based on your usage patterns, you're most active around this time."
            ))
        }
        
        // Length-based recommendations
        if avgLength > 0 {
            let suggestedTokens = (avgLength / Token.minutesPerToken)
            recommendations.append(SessionRecommendation(
                type: .lengthBased,
                message: "Your usual session length",
                suggestedTokens: suggestedTokens,
                reason: "Based on your recent \(avgLength)-minute average sessions."
            ))
        }
        
        // Goal-based recommendations
        if settings.dailyGoalMinutes > 0 {
            let todayUsage = todayUsageMinutes()
            let remainingToday = settings.dailyGoalMinutes - todayUsage
            if remainingToday > 0 {
                let tokensNeeded = (remainingToday / Token.minutesPerToken) + 1
                recommendations.append(SessionRecommendation(
                    type: .goalBased,
                    message: "Stay on track with your daily goal",
                    suggestedTokens: min(tokensNeeded, wallet.availableTokens),
                    reason: "You need \(remainingToday) more minutes to reach your daily goal."
                ))
            }
        }
        
        return recommendations.prefix(3).map { $0 } // Return max 3 recommendations
    }
    
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
    
    // MARK: - Memory Management
    
    func cleanup() {
        // Clean up old session records to prevent memory bloat
        var usage = weeklyUsage
        if usage.sessions.count > 100 {
            usage.sessions = Array(usage.sessions.suffix(100))
            weeklyUsage = usage
            saveData()
        }
        
        // Clean up old daily usage records (keep last 90 days)
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffKey = formatter.string(from: cutoffDate)
        
        var newDailyMinutes: [String: Int] = [:]
        for (key, value) in usage.dailyMinutes {
            if key >= cutoffKey {
                newDailyMinutes[key] = value
            }
        }
        
        if newDailyMinutes.count != usage.dailyMinutes.count {
            usage.dailyMinutes = newDailyMinutes
            weeklyUsage = usage
            saveData()
        }
    }
}
