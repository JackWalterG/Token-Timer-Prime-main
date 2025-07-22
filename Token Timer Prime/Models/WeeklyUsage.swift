//
//  WeeklyUsage.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

struct WeeklyUsage: Codable {
    var dailyMinutes: [String: Int] = [:]
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
