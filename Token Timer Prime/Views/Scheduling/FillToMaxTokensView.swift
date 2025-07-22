import SwiftUI

struct FillToMaxTokensView: View {
    @ObservedObject var appState: AppStateManager
    @Environment(\.presentationMode) var presentationMode
    @State private var tokensToAdd: String = ""

    private var remainingCapacity: Int {
        appState.settings.maxTokensInWallet - appState.wallet.totalTokens
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wallet Status")) {
                    Text("Current Tokens: \(appState.wallet.totalTokens)")
                    Text("Maximum Tokens: \(appState.settings.maxTokensInWallet)")
                    Text("You can add up to \(remainingCapacity) tokens.")
                }

                Section(header: Text("Add Tokens")) {
                    TextField("Number of tokens to add", text: $tokensToAdd)
                        .keyboardType(.numberPad)
                }

                Section {
                    Button("Add Tokens") {
                        if let count = Int(tokensToAdd) {
                            _ = appState.addTokensToWalletUpToMax(count)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .disabled(tokensToAdd.isEmpty || (Int(tokensToAdd) ?? 0) <= 0 || (Int(tokensToAdd) ?? 0) > remainingCapacity)
                }
            }
            .navigationTitle("Fill to Max")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
