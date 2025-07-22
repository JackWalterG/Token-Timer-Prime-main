//
//  CombinedWalletTimerView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct CombinedWalletTimerView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingAddTokens = false
    @State private var showingPasscodePrompt = false
    @State private var passcodeInput = ""
    @State private var tokensToAdd = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Wallet Section
                walletSection
                
                // Session Recommendations Section
                sessionRecommendationsSection
                
                // Token Selection Section
                tokenSelectionSection
            }
            .padding()
        }
        .alert("Enter Passcode", isPresented: $showingPasscodePrompt) {
            SecureField("Passcode", text: $passcodeInput)
            Button("Cancel", role: .cancel) {
                passcodeInput = ""
            }
            Button("Confirm") {
                if appState.settings.validatePasscode(passcodeInput) {
                    passcodeInput = ""
                    showingAddTokens = true
                } else {
                    passcodeInput = ""
                }
            }
        } message: {
            Text("Enter your passcode to add tokens to your wallet")
        }
        .sheet(isPresented: $showingAddTokens) {
            AddTokensSheet(appState: appState, tokensToAdd: $tokensToAdd)
        }
    }
    
    // MARK: - Wallet Section
    
    private var walletSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Token Wallet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Add tokens button
                Button(action: {
                    if appState.settings.isPasscodeEnabled {
                        showingPasscodePrompt = true
                    } else {
                        showingAddTokens = true
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(appState.wallet.totalTokens)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("tokens available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text(appState.formatTotalTime(minutes: appState.wallet.totalTokens * Token.minutesPerToken))
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("total time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Session Recommendations Section
    
    private var sessionRecommendationsSection: some View {
        let recommendations = appState.getSessionRecommendations()
        
        return Group {
            if !recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Recommended Sessions")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(recommendations) { recommendation in
                            recommendationCard(recommendation)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }
    
    @ViewBuilder
    private func recommendationCard(_ recommendation: SessionRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(recommendation.suggestedTokens)t")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Button("Use") {
                    appState.selectedTokens = min(recommendation.suggestedTokens, appState.wallet.availableTokens)
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .cornerRadius(6)
                .disabled(recommendation.suggestedTokens > appState.wallet.availableTokens)
            }
            
            Text(recommendation.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(12)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Token Selection Section
    
    private var tokenSelectionSection: some View {
        VStack(spacing: 20) {
            if appState.wallet.totalTokens > 0 {
                VStack(spacing: 15) {
                    Text("Select Tokens to Use")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    // Selected tokens display
                    VStack(spacing: 10) {
                        Text("\(appState.selectedTokens)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        
                        if appState.selectedTokens > 0 {
                            Text(appState.formatTotalTime(minutes: appState.selectedTokens * Token.minutesPerToken))
                                .font(.title3)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        } else {
                            Text("Select tokens to start timer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Selection controls
                    VStack(spacing: 15) {
                        // Quick selection buttons
                        HStack(spacing: 15) {
                            ForEach([1, 2, 4, 8], id: \.self) { amount in
                                Button("\(amount)") {
                                    let newSelection = min(appState.selectedTokens + amount, appState.wallet.totalTokens)
                                    appState.selectedTokens = newSelection
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 40)
                                .background(appState.selectedTokens + amount <= appState.wallet.totalTokens ? Color.blue : Color.gray)
                                .cornerRadius(8)
                                .disabled(appState.selectedTokens + amount > appState.wallet.totalTokens)
                            }
                        }
                        
                        // Plus/Minus and Clear
                        HStack(spacing: 20) {
                            Button("-") {
                                if appState.selectedTokens > 0 {
                                    appState.selectedTokens -= 1
                                }
                            }
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 40)
                            .background(appState.selectedTokens > 0 ? Color.red : Color.gray)
                            .cornerRadius(8)
                            .disabled(appState.selectedTokens <= 0)
                            
                            Button("Clear") {
                                appState.selectedTokens = 0
                            }
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .disabled(appState.selectedTokens == 0)
                            
                            Button("+") {
                                if appState.selectedTokens < appState.wallet.totalTokens {
                                    appState.selectedTokens += 1
                                }
                            }
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 40)
                            .background(appState.selectedTokens < appState.wallet.totalTokens ? Color.green : Color.gray)
                            .cornerRadius(8)
                            .disabled(appState.selectedTokens >= appState.wallet.totalTokens)
                        }
                    }
                    
                    // Begin Timer Button
                    Button("Begin Timer") {
                        appState.startTimer()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(appState.selectedTokens > 0 ? Color.blue : Color.gray)
                    .cornerRadius(12)
                    .disabled(appState.selectedTokens <= 0)
                }
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "timer.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("No Tokens Available")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Add tokens to your wallet to start using the timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    let appState = AppStateManager()
    appState.wallet.addTokens(10)
    return CombinedWalletTimerView(appState: appState)
}