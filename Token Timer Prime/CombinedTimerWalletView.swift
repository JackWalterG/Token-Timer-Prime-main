//
//  CombinedTimerWalletView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct CombinedTimerWalletView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingAddTokens = false
    @State private var showingPasscodePrompt = false
    @State private var showingEndConfirmation = false
    @State private var passcodeInput = ""
    @State private var tokensToAdd = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Wallet Section
                walletSection
                
                // Timer Section
                if appState.currentSession != nil {
                    activeTimerSection
                } else {
                    tokenSelectionSection
                }
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
        .alert("End Timer Early?", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Timer", role: .destructive) {
                appState.endTimerEarly()
            }
        } message: {
            if let session = appState.currentSession {
                let (returnedTokens, redeemedTokens) = session.tokensToReturnIfEndedEarly()
                Text("This will return \(returnedTokens) tokens to your wallet and redeem \(redeemedTokens) tokens.")
            }
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
    
    // MARK: - Active Timer Section
    
    private var activeTimerSection: some View {
        VStack(spacing: 25) {
            if let session = appState.currentSession {
                VStack(spacing: 15) {
                    Text("Timer Active")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    // Main Timer Display
                    VStack(spacing: 15) {
                        Text(appState.formatTimerDisplay(seconds: session.totalRemainingSeconds))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(session.isPaused ? .orange : .blue)
                            .monospacedDigit()
                        
                        Text(session.isPaused ? "Timer Paused" : "Time Remaining")
                            .font(.headline)
                            .foregroundColor(session.isPaused ? .orange : .secondary)
                    }
                    .padding()
                    .background((session.isPaused ? Color.orange : Color.blue).opacity(0.1))
                    .cornerRadius(16)
                    
                    // Timer Control Buttons
                    HStack(spacing: 20) {
                        // Pause/Resume Button
                        Button(session.isPaused ? "Resume Timer" : "Pause Timer") {
                            appState.recordUserActivity()
                            if session.isPaused {
                                appState.resumeTimer()
                            } else {
                                appState.pauseTimer()
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(session.isPaused ? Color.green : Color.orange)
                        .cornerRadius(12)
                    }
                    
                    // Progress information
                    VStack(spacing: 10) {
                        ProgressView(value: Double(session.totalMinutes - session.remainingMinutes), 
                                   total: Double(session.totalMinutes))
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 3)
                        
                        HStack {
                            Text("Started: \(session.originalTokens) tokens")
                            Spacer()
                            Text("\(session.totalMinutes) min total")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // End Timer Early Section
                    VStack(spacing: 15) {
                        let (returnedTokens, redeemedTokens) = session.tokensToReturnIfEndedEarly()
                        
                        VStack(spacing: 8) {
                            Text("End Early?")
                                .font(.headline)
                            
                            HStack {
                                if returnedTokens > 0 {
                                    VStack {
                                        Text("\(returnedTokens)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        Text("tokens returned")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if returnedTokens > 0 && redeemedTokens > 0 {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                }
                                
                                if redeemedTokens > 0 {
                                    VStack {
                                        Text("\(redeemedTokens)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                        Text("tokens redeemed")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("End Timer Early") {
                            showingEndConfirmation = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

#Preview {
    let appState = AppStateManager()
    appState.wallet.addTokens(10)
    return CombinedTimerWalletView(appState: appState)
}
