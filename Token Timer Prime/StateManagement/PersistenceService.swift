//
//  PersistenceService.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import Foundation

@MainActor
class PersistenceService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Save Methods
    
    func saveWallet(_ wallet: Wallet) {
        if let walletData = try? JSONEncoder().encode(wallet) {
            userDefaults.set(walletData, forKey: "wallet")
        }
    }
    
    func saveCurrentSession(_ session: TimerSession?) {
        if let session = session,
           let sessionData = try? JSONEncoder().encode(session) {
            userDefaults.set(sessionData, forKey: "currentSession")
        } else {
            userDefaults.removeObject(forKey: "currentSession")
        }
    }
    
    func saveWeeklyUsage(_ usage: WeeklyUsage) {
        if let usageData = try? JSONEncoder().encode(usage) {
            userDefaults.set(usageData, forKey: "weeklyUsage")
        }
    }
    
    func saveSettings(_ settings: AppSettings) {
        if let settingsData = try? JSONEncoder().encode(settings) {
            userDefaults.set(settingsData, forKey: "settings")
        }
    }
    
    func saveScheduledTokens(_ scheduledTokens: [ScheduledToken]) {
        if let scheduledData = try? JSONEncoder().encode(scheduledTokens) {
            userDefaults.set(scheduledData, forKey: "scheduledTokens")
        }
    }
    
    // MARK: - Load Methods
    
    func loadWallet() -> Wallet {
        if let walletData = userDefaults.data(forKey: "wallet"),
           let wallet = try? JSONDecoder().decode(Wallet.self, from: walletData) {
            return wallet
        }
        return Wallet()
    }
    
    func loadCurrentSession() -> TimerSession? {
        if let sessionData = userDefaults.data(forKey: "currentSession"),
           let session = try? JSONDecoder().decode(TimerSession.self, from: sessionData) {
            if session.isActive && !session.isCompleted {
                return session
            } else {
                // Session completed, clear it
                userDefaults.removeObject(forKey: "currentSession")
                return nil
            }
        }
        return nil
    }
    
    func loadWeeklyUsage() -> WeeklyUsage {
        if let usageData = userDefaults.data(forKey: "weeklyUsage"),
           let usage = try? JSONDecoder().decode(WeeklyUsage.self, from: usageData) {
            return usage
        }
        return WeeklyUsage()
    }
    
    func loadSettings() -> AppSettings {
        if let settingsData = userDefaults.data(forKey: "settings"),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: settingsData) {
            return settings
        }
        return AppSettings()
    }
    
    func loadScheduledTokens() -> [ScheduledToken] {
        if let scheduledData = userDefaults.data(forKey: "scheduledTokens"),
           let scheduled = try? JSONDecoder().decode([ScheduledToken].self, from: scheduledData) {
            return scheduled
        }
        return []
    }
    
    // MARK: - Convenience Methods
    
    func saveAllData(wallet: Wallet, session: TimerSession?, usage: WeeklyUsage, settings: AppSettings, scheduledTokens: [ScheduledToken]) {
        saveWallet(wallet)
        saveCurrentSession(session)
        saveWeeklyUsage(usage)
        saveSettings(settings)
        saveScheduledTokens(scheduledTokens)
    }
}
