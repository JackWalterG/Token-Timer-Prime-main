//
//  AppSettings.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

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
