//
//  TokenSelectionView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct TokenSelectionView: View {
    @ObservedObject var appState: AppStateManager
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text("Select Tokens")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Available: \(appState.wallet.totalTokens) tokens")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Token Selection
            VStack(spacing: 25) {
                Text("Select Time Tokens")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Visual token representation
                enhancedTokenSelection
                
                // Time preview
                if appState.selectedTokens > 0 {
                    VStack(spacing: 8) {
                        Text(appState.formatTotalTime(minutes: appState.selectedTokens * Token.minutesPerToken))
                            .font(.title2)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                        
                        Text("Total leisure time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1)
                    }
                }
            }
            
            // Selection controls
            VStack(spacing: 15) {
                // Stepper with haptic feedback
                HStack(spacing: 20) {
                    Button("-") {
                        if appState.selectedTokens > 0 {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring()) {
                                appState.selectedTokens -= 1
                            }
                        }
                    }
                    .buttonStyle(CircularButtonStyle(
                        backgroundColor: appState.selectedTokens > 0 ? .red : .gray,
                        isEnabled: appState.selectedTokens > 0
                    ))
                    .disabled(appState.selectedTokens <= 0)
                    
                    Text("\(appState.selectedTokens)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .frame(minWidth: 60)
                        .animation(.spring(), value: appState.selectedTokens)
                    
                    Button("+") {
                        if appState.selectedTokens < appState.wallet.totalTokens {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring()) {
                                appState.selectedTokens += 1
                            }
                        }
                    }
                    .buttonStyle(CircularButtonStyle(
                        backgroundColor: appState.selectedTokens < appState.wallet.totalTokens ? .green : .gray,
                        isEnabled: appState.selectedTokens < appState.wallet.totalTokens
                    ))
                    .disabled(appState.selectedTokens >= appState.wallet.totalTokens)
                }
                
                // Quick selection buttons
                if appState.wallet.totalTokens > 1 {
                    HStack(spacing: 12) {
                        Button("Half") {
                            HapticFeedback.selection.trigger()
                            withAnimation(.spring()) {
                                appState.selectedTokens = max(1, appState.wallet.totalTokens / 2)
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle(
                            borderColor: .blue,
                            foregroundColor: .blue,
                            isEnabled: appState.wallet.totalTokens > 1
                        ))
                        
                        Button("All") {
                            HapticFeedback.selection.trigger()
                            withAnimation(.spring()) {
                                appState.selectedTokens = appState.wallet.totalTokens
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle(
                            borderColor: .green,
                            foregroundColor: .green,
                            isEnabled: appState.wallet.totalTokens > 0
                        ))
                    }
                }
                
                // Clear selection
                Button("Clear") {
                    HapticFeedback.light.trigger()
                    withAnimation(.spring()) {
                        appState.selectedTokens = 0
                    }
                }
                .font(.headline)
                .foregroundColor(.orange)
                .disabled(appState.selectedTokens == 0)
            }
            
            Spacer()
            
            // Begin Timer Button
            Button("Begin Timer") {
                HapticFeedback.success.trigger()
                appState.startTimer()
            }
            .buttonStyle(PrimaryButtonStyle(
                backgroundColor: appState.selectedTokens > 0 ? .blue : .gray,
                isEnabled: appState.selectedTokens > 0
            ))
            .disabled(appState.selectedTokens <= 0)
        }
        .padding()
    }
    
    // MARK: - Enhanced Token Selection
    
    @ViewBuilder
    private var enhancedTokenSelection: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(appState.wallet.totalTokens, 6))
        let maxVisibleTokens = min(appState.wallet.totalTokens, 24) // Limit for performance
        
        VStack(spacing: 20) {
            // Visual token grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<maxVisibleTokens, id: \.self) { index in
                    Circle()
                        .fill(index < appState.selectedTokens ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 45, height: 45)
                        .overlay(
                            VStack(spacing: 2) {
                                Image(systemName: "clock.fill")
                                    .font(.caption2)
                                Text("15m")
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundColor(index < appState.selectedTokens ? .white : .gray)
                        )
                        .scaleEffect(index < appState.selectedTokens ? 1.1 : 1.0)
                        .shadow(color: index < appState.selectedTokens ? Color.blue.opacity(0.3) : Color.clear, radius: 4)
                        .onTapGesture {
                            HapticFeedback.selection.trigger()
                            withAnimation(.spring()) {
                                appState.selectedTokens = index + 1
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.selectedTokens)
                }
            }
            .padding(.horizontal)
            
            // Show count if more tokens than displayed
            if appState.wallet.totalTokens > maxVisibleTokens {
                Text("+ \(appState.wallet.totalTokens - maxVisibleTokens) more tokens available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let appState = AppStateManager()
    appState.wallet.addTokens(10)
    return TokenSelectionView(appState: appState)
}
