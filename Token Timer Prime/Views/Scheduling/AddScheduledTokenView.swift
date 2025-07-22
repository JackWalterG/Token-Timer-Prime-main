//
//  AddScheduledTokenView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import SwiftUI

struct AddScheduledTokenView: View {
    @ObservedObject var appState: AppStateManager
    @Environment(\.presentationMode) var presentationMode
    
    // Form state
    @State private var title: String = ""
    @State private var tokenCount: String = "1"
    @State private var notes: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var recurrenceType: RecurrenceType = .daily
    @State private var useMaxWalletLimit: Bool = false
    @State private var maxWalletTokens: String = ""
    
    // Validation
    private var isValidForm: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (Int(tokenCount) ?? 0) > 0 &&
        (!useMaxWalletLimit || (Int(maxWalletTokens) ?? 0) > 0)
    }
    
    private var tokenCountInt: Int {
        Int(tokenCount) ?? 1
    }
    
    private var totalTimeFormatted: String {
        appState.formatTotalTime(minutes: tokenCountInt * Token.minutesPerToken)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section(header: Text("Schedule Details")) {
                    TextField("Schedule Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    HStack {
                        TextField("Number of tokens", text: $tokenCount)
                            .keyboardType(.numberPad)
                        
                        Spacer()
                        
                        if tokenCountInt > 0 {
                            Text("(\(totalTimeFormatted))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                }
                
                // Timing Section
                Section(header: Text("When & How Often")) {
                    DatePicker("First Occurrence", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Recurrence", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Wallet Limit Section
                Section(header: Text("Wallet Limit (Optional)"), 
                       footer: Text("If enabled, tokens will only be added if your wallet has space below this limit.")) {
                    Toggle("Use Maximum Wallet Limit", isOn: $useMaxWalletLimit)
                    
                    if useMaxWalletLimit {
                        TextField("Max wallet tokens", text: $maxWalletTokens)
                            .keyboardType(.numberPad)
                    }
                }
                
                // Preview Section
                Section(header: Text("Preview")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Title:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(title.isEmpty ? "Untitled Schedule" : title)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Tokens:")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(tokenCountInt) tokens (\(totalTimeFormatted))")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Frequency:")
                                .fontWeight(.medium)
                            Spacer()
                            Text(recurrenceType.displayName)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                                .font(.caption)
                        }
                        
                        if useMaxWalletLimit, let maxTokens = Int(maxWalletTokens), maxTokens > 0 {
                            HStack {
                                Text("Wallet Limit:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(maxTokens) tokens max")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        if !notes.isEmpty {
                            HStack(alignment: .top) {
                                Text("Notes:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(notes)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveScheduledToken()
                    }
                    .disabled(!isValidForm)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveScheduledToken() {
        let maxTokens = useMaxWalletLimit ? Int(maxWalletTokens) : nil
        
        let scheduledToken = ScheduledToken(
            tokenCount: tokenCountInt,
            scheduledDate: scheduledDate,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            recurrenceType: recurrenceType,
            isActive: true,
            maxWalletTokens: maxTokens
        )
        
        appState.addScheduledToken(scheduledToken)
        appState.toastManager.show("Schedule created successfully!", type: .success)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    let appState = AppStateManager()
    return AddScheduledTokenView(appState: appState)
}