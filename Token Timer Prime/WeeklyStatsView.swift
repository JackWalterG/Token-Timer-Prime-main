//
//  WeeklyStatsView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct WeeklyStatsView: View {
    @ObservedObject var appState: AppStateManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                Text("Usage Analytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Main stats
                VStack(spacing: 20) {
                    // Total time this week
                    VStack(spacing: 10) {
                        Text("This Week")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1f hours", appState.weeklyUsage.totalHoursThisWeek))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        Text(appState.formatTotalTime(minutes: appState.weeklyUsage.totalMinutesThisWeek))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Tokens equivalent
                    VStack(spacing: 5) {
                        Text("Equivalent to:")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        let tokensUsed = appState.weeklyUsage.totalMinutesThisWeek / Token.minutesPerToken
                        Text("\(tokensUsed) tokens redeemed")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                // Goals Progress Section
                goalsProgressSection
                
                // Session Analytics Section
                sessionAnalyticsSection
                
                // Usage Insights Section
                usageInsightsSection
                
                Spacer()
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var goalsProgressSection: some View {
        VStack(spacing: 15) {
            Text("Goals Progress")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Daily Goal
                goalProgressRow(
                    title: "Daily Goal",
                    progress: appState.dailyGoalProgress(),
                    current: appState.todayUsageMinutes(),
                    target: appState.settings.dailyGoalMinutes,
                    color: .orange
                )
                
                // Weekly Goal
                goalProgressRow(
                    title: "Weekly Goal",
                    progress: appState.weeklyGoalProgress(),
                    current: appState.weeklyUsage.totalMinutesThisWeek,
                    target: appState.settings.weeklyGoalMinutes,
                    color: .blue
                )
                
                // Monthly Goal
                goalProgressRow(
                    title: "Monthly Goal",
                    progress: appState.monthlyGoalProgress(),
                    current: appState.monthlyUsageMinutes(),
                    target: appState.settings.monthlyGoalMinutes,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var sessionAnalyticsSection: some View {
        VStack(spacing: 15) {
            Text("Session Insights")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                // Average Session Length
                analyticsCard(
                    title: "Avg Session",
                    value: "\(appState.weeklyUsage.averageSessionLength) min",
                    subtitle: "Recent average",
                    color: .green
                )
                
                // Favorite Session Lengths
                analyticsCard(
                    title: "Favorite Lengths",
                    value: favoriteSessionsText,
                    subtitle: "Most common",
                    color: .teal
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var usageInsightsSection: some View {
        VStack(spacing: 15) {
            Text("Usage Patterns")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Peak Usage Hours
                VStack(spacing: 8) {
                    Text("Peak Usage Hours")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(appState.weeklyUsage.peakUsageHours(), id: \.self) { hour in
                            Text(formatHour(hour))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func goalProgressRow(title: String, progress: Double, current: Int, target: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(current)/\(target) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func analyticsCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var favoriteSessionsText: String {
        let favorites = appState.weeklyUsage.favoriteSessionLengths
        if favorites.isEmpty {
            return "No data"
        }
        return favorites.map { "\($0)t" }.joined(separator: ", ")
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

#Preview {
    let appState = AppStateManager()
    appState.weeklyUsage.addUsage(minutes: 120) // 2 hours of usage
    return WeeklyStatsView(appState: appState)
}
