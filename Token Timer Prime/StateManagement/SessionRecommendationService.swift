//
//  SessionRecommendationService.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import Foundation

// MARK: - Session Recommendation Models

enum RecommendationType {
    case timeOptimal
    case lengthBased
    case goalBased
    case usage
}

struct SessionRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let message: String
    let suggestedTokens: Int
    let reason: String
}

@MainActor
class SessionRecommendationService: ObservableObject {
    
    // MARK: - Public Methods
    
    func getSessionRecommendations(weeklyUsage: WeeklyUsage, settings: AppSettings) -> [SessionRecommendation] {
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
            let todayUsage = getTodayUsageMinutes(weeklyUsage: weeklyUsage)
            let remainingToday = settings.dailyGoalMinutes - todayUsage
            if remainingToday > 0 {
                let tokensNeeded = (remainingToday / Token.minutesPerToken) + 1
                recommendations.append(SessionRecommendation(
                    type: .goalBased,
                    message: "Stay on track with your daily goal",
                    suggestedTokens: tokensNeeded,
                    reason: "You need \(remainingToday) more minutes to reach your daily goal."
                ))
            }
        }
        
        // Usage pattern recommendations
        if weeklyUsage.sessions.count >= 5 {
            let recentSessions = Array(weeklyUsage.sessions.suffix(5))
            let avgTokens = recentSessions.map { $0.originalTokens }.reduce(0, +) / recentSessions.count
            
            recommendations.append(SessionRecommendation(
                type: .usage,
                message: "Based on your recent activity",
                suggestedTokens: avgTokens,
                reason: "Your last 5 sessions averaged \(avgTokens) tokens."
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func getTodayUsageMinutes(weeklyUsage: WeeklyUsage) -> Int {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: today)
        return weeklyUsage.dailyMinutes[todayKey, default: 0]
    }
}
