//
//  ContentView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppStateManager()
    @State private var showingOnboarding = false
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    
    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else {
                mainAppView
            }
        }
        .onAppear {
            simulateAppLoad()
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(appState: appState)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 30) {
            // App Logo/Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "timer")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 2) * 0.1)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: loadingProgress)
            
            VStack(spacing: 15) {
                Text("Token Timer Prime")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Loading your data...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            VStack(spacing: 10) {
                ProgressView(value: loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                    .frame(maxWidth: 200)
                
                Text(loadingText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
    
    @ViewBuilder
    private var mainAppView: some View {
        TabView {
            // Timer view (using CombinedTimerWalletView)
            CombinedTimerWalletView(appState: appState)
                .tabItem {
                    Image(systemName: "timer")
                    Text("Timer")
                }
            
            // Scheduled Tokens
            ScheduledTokensView(appState: appState)
                .tabItem {
                    Image(systemName: "calendar.badge.plus")
                    Text("Schedule")
                }
            
            // Weekly stats
            WeeklyStatsView(appState: appState)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Stats")
                }
            
            // Settings
            SettingsView(appState: appState)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
        .preferredColorScheme(appState.settings.isDarkModeEnabled ? .dark : .light)
        .onAppear {
            if !appState.settings.hasCompletedOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingOnboarding = true
                }
            }
        }
    }
    
    private var loadingText: String {
        switch loadingProgress {
        case 0.0..<0.3:
            return "Initializing app..."
        case 0.3..<0.6:
            return "Loading your wallet..."
        case 0.6..<0.9:
            return "Preparing timer data..."
        default:
            return "Almost ready..."
        }
    }
    
    private func simulateAppLoad() {
        // Simulate loading process with realistic steps
        let loadingSteps = [
            (delay: 0.2, progress: 0.2),
            (delay: 0.3, progress: 0.4),
            (delay: 0.2, progress: 0.6),
            (delay: 0.2, progress: 0.8),
            (delay: 0.1, progress: 1.0)
        ]
        
        var currentDelay = 0.0
        for step in loadingSteps {
            currentDelay += step.delay
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingProgress = step.progress
                }
                
                if step.progress >= 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            isLoading = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
