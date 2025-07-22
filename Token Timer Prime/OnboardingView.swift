//
//  OnboardingView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppStateManager
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss
    
    let pages = OnboardingPage.allPages
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, appState: appState)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Navigation buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground))
        .onAppear {
            // Give the user 3 starter tokens
            var wallet = appState.wallet
            wallet.addTokens(3)
            appState.updateWallet(wallet)
        }
    }
    
    private func completeOnboarding() {
        var settings = appState.settings
        settings.hasCompletedOnboarding = true
        appState.updateSettings(settings)
        dismiss()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject var appState: AppStateManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Icon
                ZStack {
                    Circle()
                        .fill(page.iconColor.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: page.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(page.iconColor)
                }
                .padding(.top, 40)
                
                // Title and description
                VStack(spacing: 20) {
                    Text(page.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(page.description)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                // Interactive demo or content
                page.demoView(appState)
                    .padding(.horizontal, 20)
                
                Spacer(minLength: 60)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let demoView: @MainActor (AppStateManager) -> AnyView
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Token Timer",
            description: "Manage your leisure time with a token-based system. Each token represents 15 minutes of relaxation.",
            iconName: "timer",
            iconColor: .blue,
            demoView: { _ in
                AnyView(
                    VStack(spacing: 20) {
                        HStack(spacing: 15) {
                            ForEach(0..<3, id: \.self) { _ in
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Text("15m")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Text("3 tokens = 45 minutes")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                )
            }
        ),
        
        OnboardingPage(
            title: "Earn Tokens",
            description: "Add tokens to your wallet when you've completed tasks, achieved goals, or deserve some leisure time.",
            iconName: "plus.circle.fill",
            iconColor: .green,
            demoView: { appState in
                AnyView(
                    VStack(spacing: 20) {
                        Text("You start with 3 free tokens!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        HStack {
                            Image(systemName: "creditcard.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            
                            Text("Wallet: \(appState.wallet.totalTokens) tokens")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Tip: Set up goals in Settings to track your progress!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                )
            }
        ),
        
        OnboardingPage(
            title: "Start Your Timer",
            description: "Select tokens from your wallet to start a timer session. You can pause, resume, and track your time easily.",
            iconName: "play.circle.fill",
            iconColor: .blue,
            demoView: { _ in
                AnyView(
                    VStack(spacing: 20) {
                        VStack(spacing: 10) {
                            HStack {
                                Button(action: {}) {
                                    Image(systemName: "pause.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.orange)
                                }
                                
                                Text("15:00")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .monospacedDigit()
                                
                                Button(action: {}) {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            ProgressView(value: 0.5)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                        }
                        
                        Text("Pause anytime and resume later")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                )
            }
        ),
        
        OnboardingPage(
            title: "Smart Features",
            description: "Enjoy auto-pause detection, session recommendations, grace periods, and comprehensive analytics.",
            iconName: "brain.head.profile",
            iconColor: .purple,
            demoView: { _ in
                AnyView(
                    VStack(spacing: 15) {
                        FeatureRow(icon: "pause.circle", title: "Auto-Pause", description: "Pauses when you're away")
                        FeatureRow(icon: "lightbulb", title: "Recommendations", description: "Smart session suggestions")
                        FeatureRow(icon: "chart.bar", title: "Analytics", description: "Track your patterns")
                        FeatureRow(icon: "target", title: "Goals", description: "Set and achieve targets")
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(15)
                )
            }
        ),
        
        OnboardingPage(
            title: "You're All Set!",
            description: "Start managing your leisure time effectively. Remember: each token is a reward for your accomplishments.",
            iconName: "checkmark.circle.fill",
            iconColor: .green,
            demoView: { _ in
                AnyView(
                    VStack(spacing: 20) {
                        Text("🎉")
                            .font(.system(size: 60))
                        
                        VStack(spacing: 10) {
                            Text("Quick Tips:")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(text: "Visit Settings to customize your experience")
                                TipRow(text: "Check Stats to see your usage patterns")
                                TipRow(text: "Use grace periods for flexibility")
                                TipRow(text: "Set goals to stay motivated")
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                )
            }
        )
    ]
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(.green)
                .fontWeight(.bold)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(appState: AppStateManager())
}
