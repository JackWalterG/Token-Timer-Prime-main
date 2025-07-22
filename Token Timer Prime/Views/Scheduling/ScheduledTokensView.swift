//
//  ScheduledTokensView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct ScheduledTokensView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingAddSchedule = false
    @State private var showingFillToMax = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Fill to Maximum section (only show if max tokens is set)
                if appState.settings.maxTokensInWallet > 0 {
                    fillToMaxSection
                }
                
                if appState.scheduledTokens.isEmpty {
                    emptyStateView
                } else {
                    scheduledTokensList
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scheduled Tokens")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !appState.scheduledTokens.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Schedule") {
                            showingAddSchedule = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                }
            }        .sheet(isPresented: $showingAddSchedule) {
            AddScheduledTokenView(appState: appState)
        }
            .sheet(isPresented: $showingFillToMax) {
                FillToMaxTokensView(appState: appState)
            }
        }
    }
    
    @ViewBuilder
    private var fillToMaxSection: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Fill to Maximum")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add tokens up to your maximum wallet limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Fill Now") {
                    showingFillToMax = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(canFillToMax ? Color.green : Color.gray)
                .cornerRadius(20)
                .disabled(!canFillToMax)
            }
            
            // Current status
            VStack(spacing: 8) {
                HStack {
                    Text("Current:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(appState.wallet.totalTokens) tokens")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Maximum:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(appState.settings.maxTokensInWallet) tokens")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if canFillToMax {
                    HStack {
                        Text("Can add:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(tokensNeededToFill) tokens")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(15)
    }
    
    private var canFillToMax: Bool {
        appState.settings.maxTokensInWallet > 0 && appState.wallet.totalTokens < appState.settings.maxTokensInWallet
    }
    
    private var tokensNeededToFill: Int {
        max(0, appState.settings.maxTokensInWallet - appState.wallet.totalTokens)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Scheduled Tokens")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Schedule tokens to be automatically added to your wallet at specific times")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Create First Schedule") {
                showingAddSchedule = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(25)
        }
        .padding()
    }
    
    @ViewBuilder
    private var scheduledTokensList: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(appState.scheduledTokens.sorted(by: { lhs, rhs in
                    if let lhsNext = lhs.nextOccurrence, let rhsNext = rhs.nextOccurrence {
                        return lhsNext < rhsNext
                    }
                    return lhs.createdDate > rhs.createdDate
                })) { scheduledToken in
                    ScheduledTokenCard(scheduledToken: scheduledToken, appState: appState)
                }
            }
        }
    }
}

struct ScheduledTokenCard: View {
    let scheduledToken: ScheduledToken
    @ObservedObject var appState: AppStateManager
    @State private var showingDeleteAlert = false
    @State private var showingEditView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            scheduleInfoSection
            actionSection
        }
        .padding()
        .background(scheduledToken.isActive ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(scheduledToken.isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingEditView) {
            EditScheduledTokenView(appState: appState, scheduledToken: scheduledToken)
        }
        .alert("Delete Schedule", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                appState.removeScheduledToken(scheduledToken.id)
            }
        } message: {
            Text("Are you sure you want to delete this scheduled token? This action cannot be undone.")
        }
    }
    
    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scheduledToken.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(scheduledToken.tokenCount) tokens (\(appState.formatTotalTime(minutes: scheduledToken.tokenCount * Token.minutesPerToken)))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(scheduledToken.recurrenceType.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
                
                Toggle("", isOn: Binding(
                    get: { scheduledToken.isActive },
                    set: { _ in
                        appState.toggleScheduledToken(scheduledToken.id)
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
                .scaleEffect(0.8)
            }
        }
    }
    
    private var scheduleInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if let nextOccurrence = scheduledToken.nextOccurrence {
                    if scheduledToken.isActive {
                        Text("Next: \(nextOccurrence.formattedMedium())")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    } else {
                        Text("Paused")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(scheduledToken.isPastDue ? "Past due" : "No upcoming occurrence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let maxTokens = scheduledToken.maxWalletTokens {
                HStack {
                    Image(systemName: "wallet.pass.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text("Wallet max: \(maxTokens) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let notes = scheduledToken.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var actionSection: some View {
        HStack {
            Button("Edit") {
                showingEditView = true
            }
            .font(.caption)
            .foregroundColor(.blue)
            
            Spacer()
            
            Button("Delete") {
                showingDeleteAlert = true
            }
            .font(.caption)
            .foregroundColor(.red)
        }
    }
}

#Preview {
    let appState = AppStateManager()
    // Add some sample scheduled tokens
    appState.scheduledTokens = [
        ScheduledToken(
            tokenCount: 2,
            scheduledDate: Date().addingTimeInterval(3600),
            title: "Daily Reading Reward",
            notes: "For completing daily reading goal",
            recurrenceType: .daily,
            maxWalletTokens: 25
        ),
        ScheduledToken(
            tokenCount: 5,
            scheduledDate: Date().addingTimeInterval(86400 * 7),
            title: "Weekly Review",
            recurrenceType: .weekly
        )
    ]
    return ScheduledTokensView(appState: appState)
}