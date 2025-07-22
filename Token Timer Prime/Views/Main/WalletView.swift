//
//  WalletView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct WalletView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingAddTokens = false
    @State private var showingPasscodePrompt = false
    @State private var passcodeInput = ""
    @State private var tokensToAdd = ""
    
    var body: some View {
        VStack(spacing: 30) {
            if appState.wallet.totalTokens == 0 {
                improvedEmptyState
            } else {
                walletContentView
            }
        }
        .padding()
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
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var walletContentView: some View {
        VStack(spacing: 30) {
            // Enhanced Wallet Header
            VStack(spacing: 15) {
                Text("Token Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Animated token display
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 140, height: 140)
                    
                    VStack(spacing: 8) {
                        Text("\(appState.wallet.totalTokens)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .animation(.spring(), value: appState.wallet.totalTokens)
                        
                        Text("tokens")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
                
                // Time equivalent
                Text("≈ \(appState.formatTotalTime(minutes: appState.wallet.totalTokens * Token.minutesPerToken))")
                    .font(.title3)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
            }
            
            // Add Tokens Button
            Button(action: {
                HapticFeedback.medium.trigger()
                if appState.settings.isPasscodeEnabled {
                    showingPasscodePrompt = true
                } else {
                    showingAddTokens = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Tokens")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: .green))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var improvedEmptyState: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                VStack(spacing: 12) {
                    Image(systemName: "timer.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("0")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 15) {
                Text("No Tokens Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add tokens to start timing your leisure activities. Each token gives you 15 minutes of guilt-free relaxation time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 20)
            }
            
            // Primary action
            Button("Add Your First Tokens") {
                HapticFeedback.medium.trigger()
                if appState.settings.isPasscodeEnabled {
                    showingPasscodePrompt = true
                } else {
                    showingAddTokens = true
                }
            }
            .buttonStyle(PrimaryButtonStyle(backgroundColor: .green))
            .padding(.horizontal, 30)
            
            Spacer()
        }
    }
}

struct AddTokensSheet: View {
    @ObservedObject var appState: AppStateManager
    @Binding var tokensToAdd: String
    @Environment(\.dismiss) private var dismiss
    @State private var tokenCount: Int = 1
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Add Tokens to Wallet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 20) {
                    Button(action: {
                        if tokenCount > 1 {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring()) {
                                tokenCount -= 1
                            }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(tokenCount > 1 ? .red : .gray)
                    }
                    
                    Text("\(tokenCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(minWidth: 80)
                        .animation(.spring(), value: tokenCount)
                    
                    Button(action: {
                        HapticFeedback.light.trigger()
                        withAnimation(.spring()) {
                            tokenCount += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    }
                }
                
                Text("Time value: \(appState.formatTotalTime(minutes: tokenCount * Token.minutesPerToken))")
                    .font(.headline)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                
                Button("Add \(tokenCount) Token\(tokenCount > 1 ? "s" : "")") {
                    HapticFeedback.success.trigger()
                    appState.addTokensToWallet(tokenCount)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(backgroundColor: .blue))
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        HapticFeedback.light.trigger()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WalletView(appState: AppStateManager())
}
