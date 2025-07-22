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
            VStack(spacing: 20) {
                Text("Tokens to redeem:")
                    .font(.title2)
                
                // Selected tokens display
                Text("\(appState.selectedTokens)")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                // Time preview
                if appState.selectedTokens > 0 {
                    Text(appState.formatTotalTime(minutes: appState.selectedTokens * Token.minutesPerToken))
                        .font(.title3)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            
            // Selection controls
            VStack(spacing: 15) {
                // Stepper
                HStack(spacing: 20) {
                    Button("-") {
                        if appState.selectedTokens > 0 {
                            appState.selectedTokens -= 1
                        }
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(appState.selectedTokens > 0 ? Color.red : Color.gray)
                    .cornerRadius(25)
                    .disabled(appState.selectedTokens <= 0)
                    
                    Button("+") {
                        if appState.selectedTokens < appState.wallet.totalTokens {
                            appState.selectedTokens += 1
                        }
                    }
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(appState.selectedTokens < appState.wallet.totalTokens ? Color.green : Color.gray)
                    .cornerRadius(25)
                    .disabled(appState.selectedTokens >= appState.wallet.totalTokens)
                }
                
                // Clear selection
                Button("Clear") {
                    appState.selectedTokens = 0
                }
                .font(.headline)
                .foregroundColor(.orange)
                .disabled(appState.selectedTokens == 0)
            }
            
            Spacer()
            
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
        .padding()
    }
}

#Preview {
    let appState = AppStateManager()
    appState.wallet.addTokens(10)
    return TokenSelectionView(appState: appState)
}
