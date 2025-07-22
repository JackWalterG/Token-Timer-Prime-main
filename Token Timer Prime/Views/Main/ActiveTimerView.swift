//
//  ActiveTimerView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct ActiveTimerView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingEndConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 40) {
            // Error handling for corrupted session
            if let session = appState.currentSession {
                if session.totalMinutes <= 0 || session.originalTokens <= 0 {
                    corruptedSessionView
                } else {
                    validSessionView(session: session)
                }
            } else {
                noSessionView
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private var corruptedSessionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Session Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The current timer session appears to be corrupted. This may happen due to unexpected app behavior.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Reset Session") {
                resetCorruptedSession()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.orange)
            .cornerRadius(12)
        }
        .padding()
    }
    
    @ViewBuilder
    private var noSessionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Active Session")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("It looks like you don't have an active timer session. Return to the timer tab to start a new session.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    @ViewBuilder
    private func validSessionView(session: TimerSession) -> some View {
        VStack(spacing: 40) {
            // Timer Header
            VStack(spacing: 10) {
                Text(session.isPaused ? "Timer Paused" : "Leisure Time Active")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(session.isPaused ? .orange : .secondary)
                
                Text("Time Remaining")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Main Timer Display
            VStack(spacing: 20) {
                // Linear timer display
                linearTimerView(session: session)
                
                // Grace period indicator
                if session.isInGracePeriod(gracePeriodMinutes: appState.settings.gracePeriodMinutes) {
                    Text("Grace Period - All tokens will be returned if ended early")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                // Progress information
                VStack(spacing: 10) {
                    Text("Original: \(session.originalTokens) tokens (\(appState.formatTotalTime(minutes: session.totalMinutes)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Progress bar
                    ProgressView(value: Double(session.totalMinutes - session.remainingMinutes), 
                               total: Double(session.totalMinutes))
                        .progressViewStyle(LinearProgressViewStyle(tint: session.isPaused ? .orange : .blue))
                        .scaleEffect(y: 2)
                }
            }
            
            // Timer Control Buttons
            HStack(spacing: 20) {
                // Pause/Resume Button
                Button(session.isPaused ? "Resume Timer" : "Pause Timer") {
                    HapticFeedback.medium.trigger()
                    appState.recordUserActivity()
                    if session.isPaused {
                        appState.resumeTimer()
                    } else {
                        appState.pauseTimer()
                    }
                }
                .buttonStyle(PrimaryButtonStyle(
                    backgroundColor: session.isPaused ? .green : .orange,
                    isEnabled: true
                ))
            }
            
            // End Timer Early Section
            VStack(spacing: 20) {
                let (returnedTokens, redeemedTokens) = session.tokensToReturnIfEndedEarly(gracePeriodMinutes: appState.settings.gracePeriodMinutes)
                
                VStack(spacing: 10) {
                    Text("End Early?")
                        .font(.headline)
                    
                    if session.isInGracePeriod(gracePeriodMinutes: appState.settings.gracePeriodMinutes) {
                        Text("Grace period: All \(session.originalTokens) tokens will be returned")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Returns \(returnedTokens) tokens, redeems \(redeemedTokens) tokens")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Button("End Timer Early") {
                    HapticFeedback.warning.trigger()
                    appState.recordUserActivity()
                    showingEndConfirmation = true
                }
                .buttonStyle(PrimaryButtonStyle(
                    backgroundColor: .red,
                    isEnabled: true
                ))
            }
        }
        .padding()
        .alert("End Timer Early?", isPresented: $showingEndConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Timer", role: .destructive) {
                appState.endTimerEarly()
            }
        } message: {
            if session.isInGracePeriod(gracePeriodMinutes: appState.settings.gracePeriodMinutes) {
                Text("Grace period: All \(session.originalTokens) tokens will be returned to your wallet.")
            } else {
                let (returnedTokens, redeemedTokens) = session.tokensToReturnIfEndedEarly(gracePeriodMinutes: appState.settings.gracePeriodMinutes)
                Text("This will return \(returnedTokens) tokens to your wallet and redeem \(redeemedTokens) tokens.")
            }
        }
    }
    
    // MARK: - Timer Display Views
    
    @ViewBuilder
    private func linearTimerView(session: TimerSession) -> some View {
        enhancedTimerView(session: session)
    }
    
    @ViewBuilder
    private func enhancedTimerView(session: TimerSession) -> some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 220, height: 220)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: Double(session.totalMinutes - session.remainingMinutes) / Double(session.totalMinutes))
                .stroke(
                    session.isPaused ? Color.orange : Color.blue,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: session.remainingMinutes)
            
            // Timer text
            VStack(spacing: 8) {
                Text(appState.formatTimerCountdown(totalSeconds: session.totalRemainingSeconds))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(session.isPaused ? .orange : .blue)
                    .monospacedDigit()
                
                Text(session.isPaused ? "Paused" : "Remaining")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            
            // Subtle glow effect when active
            if !session.isPaused {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 240, height: 240)
                    .scaleEffect(1.0)
                    .opacity(0.6)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: session.remainingMinutes)
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func resetCorruptedSession() {
        // Try to salvage any remaining time and return proportional tokens
        if let session = appState.currentSession {
            let elapsedMinutes = Int(Date().timeIntervalSince(session.startTime) / 60)
            let maxTokensToReturn = max(0, session.originalTokens - (elapsedMinutes / Token.minutesPerToken))
            
            // Return at least some tokens as a safety measure
            let tokensToReturn = max(1, maxTokensToReturn)
            var wallet = appState.wallet
            wallet.addTokens(tokensToReturn)
            appState.updateWallet(wallet)
            
            errorMessage = "Session reset. \(tokensToReturn) tokens returned to your wallet as compensation."
            showingErrorAlert = true
        }
        
        // Clear the corrupted session
        appState.currentSession = nil
    }
}

#Preview {
    let appState = AppStateManager()
    appState.currentSession = TimerSession(tokens: 4)
    return ActiveTimerView(appState: appState)
}
