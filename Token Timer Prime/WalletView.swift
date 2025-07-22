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
            // Wallet Header
            VStack(spacing: 10) {
                Text("Token Wallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(appState.wallet.totalTokens)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text("tokens available")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Add Tokens Button
            Button(action: {
                if appState.settings.isPasscodeEnabled {
                    showingPasscodePrompt = true
                } else {
                    showingAddTokens = true
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Tokens")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            
            Spacer()
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
                            tokenCount -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    }
                    
                    Text("\(tokenCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    
                    Button(action: {
                        tokenCount += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                    }
                }
                
                Text("Time value: \(appState.formatTotalTime(minutes: tokenCount * Token.minutesPerToken))")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Button("Add \(tokenCount) Token\(tokenCount > 1 ? "s" : "")") {
                    appState.addTokensToWallet(tokenCount)
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
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
