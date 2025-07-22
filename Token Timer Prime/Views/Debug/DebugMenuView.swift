//
//  DebugMenuView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct DebugMenuView: View {
    @ObservedObject var appState: AppStateManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Data Management")) {
                Button("Reset Token Wallet") {
                    appState.resetWallet()
                }
                .foregroundColor(.red)

                Button("Reset Usage Stats") {
                    appState.resetStats()
                }
                .foregroundColor(.red)
            }

            Section(header: Text("Timer Controls")) {
                Button("Fast Forward Timer to 5s") {
                    appState.fastForwardTimer()
                    // Dismiss the settings view to go back to the tab view
                    // This relies on the view hierarchy popping back.
                    // A more robust solution might involve a shared state for navigation.
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(appState.currentSession == nil)
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DebugMenuView(appState: AppStateManager())
}
