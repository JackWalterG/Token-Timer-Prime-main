//
//  SettingsView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppStateManager
    @State private var showingPasscodeSetup = false
    @State private var showingOnboarding = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var currentPasscode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Passcode Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Security")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Toggle("Passcode Protection", isOn: Binding(
                            get: { appState.settings.isPasscodeEnabled },
                            set: { enabled in
                                if enabled {
                                    showingPasscodeSetup = true
                            } else {
                                disablePasscode()
                            }
                        }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        
                        Text("Require passcode to add tokens to wallet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    if appState.settings.isPasscodeEnabled {
                        Button("Change Passcode") {
                            showingPasscodeSetup = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                    }
                    
                    // Display Format Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Display")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Time Format
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Time Format")
                                .font(.headline)
                            
                            Picker("Time Format", selection: Binding(
                                get: { appState.settings.timeDisplayFormat },
                                set: { format in
                                    var settings = appState.settings
                                    settings.timeDisplayFormat = format
                                    appState.updateSettings(settings)
                                }
                            )) {
                                ForEach(TimeDisplayFormat.allCases, id: \.self) { format in
                                    Text(format.displayName).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Text("Choose how time is displayed throughout the app.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Grace Period
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Grace Period")
                                .font(.headline)
                            
                            HStack {
                                Text("Duration:")
                                Spacer()
                                Picker("Grace Period", selection: Binding(
                                    get: { appState.settings.gracePeriodMinutes },
                                    set: { minutes in
                                        var settings = appState.settings
                                        settings.gracePeriodMinutes = minutes
                                        appState.updateSettings(settings)
                                    }
                                )) {
                                    Text("1 minute").tag(1)
                                    Text("2 minutes").tag(2)
                                    Text("3 minutes").tag(3)
                                    Text("5 minutes").tag(5)
                                    Text("None").tag(0)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            Text("Time period where ending early returns all tokens.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Dark Mode Toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Dark Mode", isOn: Binding(
                                get: { appState.settings.isDarkModeEnabled },
                                set: { isDark in
                                    var settings = appState.settings
                                    settings.isDarkModeEnabled = isDark
                                    appState.updateSettings(settings)
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                            
                            Text("Use dark appearance throughout the app.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Auto-Pause Settings
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Auto-Pause", isOn: Binding(
                                get: { appState.settings.isAutoPauseEnabled },
                                set: { enabled in
                                    var settings = appState.settings
                                    settings.isAutoPauseEnabled = enabled
                                    appState.updateSettings(settings)
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                            
                            if appState.settings.isAutoPauseEnabled {
                                HStack {
                                    Text("After:")
                                    Spacer()
                                    Picker("Auto-Pause Duration", selection: Binding(
                                        get: { appState.settings.autoPauseMinutes },
                                        set: { minutes in
                                            var settings = appState.settings
                                            settings.autoPauseMinutes = minutes
                                            appState.updateSettings(settings)
                                        }
                                    )) {
                                        Text("5 minutes").tag(5)
                                        Text("10 minutes").tag(10)
                                        Text("15 minutes").tag(15)
                                        Text("20 minutes").tag(20)
                                        Text("30 minutes").tag(30)
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                            
                            Text("Automatically pause timer when app is inactive.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Goals Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Usage Goals")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            // Daily Goal
                            goalSettingRow(
                                title: "Daily Goal",
                                value: Binding(
                                    get: { appState.settings.dailyGoalMinutes },
                                    set: { minutes in
                                        var settings = appState.settings
                                        settings.dailyGoalMinutes = minutes
                                        appState.updateSettings(settings)
                                    }
                                ),
                                units: "minutes per day"
                            )
                            
                            // Weekly Goal
                            goalSettingRow(
                                title: "Weekly Goal",
                                value: Binding(
                                    get: { appState.settings.weeklyGoalMinutes },
                                    set: { minutes in
                                        var settings = appState.settings
                                        settings.weeklyGoalMinutes = minutes
                                        appState.updateSettings(settings)
                                    }
                                ),
                                units: "minutes per week"
                            )
                            
                            // Monthly Goal
                            goalSettingRow(
                                title: "Monthly Goal",
                                value: Binding(
                                    get: { appState.settings.monthlyGoalMinutes },
                                    set: { minutes in
                                        var settings = appState.settings
                                        settings.monthlyGoalMinutes = minutes
                                        appState.updateSettings(settings)
                                    }
                                ),
                                units: "minutes per month"
                            )
                            
                            Text("Set to 0 to disable goal tracking. Goals help you monitor your leisure time usage.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Help & Support Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Help & Support")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Button("Show Tutorial") {
                                showingOnboarding = true
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            
                            Text("Replay the getting started tutorial to learn about all features.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Debug Menu Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Developer")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        NavigationLink(destination: DebugMenuView(appState: appState)) {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                Text("Debug Menu")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                        
                        Text("Access developer and debugging tools.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingPasscodeSetup) {
            PasscodeSetupSheet(
                appState: appState,
                newPasscode: $newPasscode,
                confirmPasscode: $confirmPasscode,
                currentPasscode: $currentPasscode,
                showingError: $showingError,
                errorMessage: $errorMessage
            )
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView(appState: appState)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private func goalSettingRow(title: String, value: Binding<Int>, units: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(units)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Stepper("", value: value, in: 0...1440, step: 15)
                    .labelsHidden()
                
                Spacer()
                
                Text(value.wrappedValue == 0 ? "No goal" : "\(value.wrappedValue)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(value.wrappedValue == 0 ? .secondary : .primary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func disablePasscode() {
        var settings = appState.settings
        settings.isPasscodeEnabled = false
        settings.passcode = ""
        appState.updateSettings(settings)
    }
}

struct PasscodeSetupSheet: View {
    @ObservedObject var appState: AppStateManager
    @Binding var newPasscode: String
    @Binding var confirmPasscode: String
    @Binding var currentPasscode: String
    @Binding var showingError: Bool
    @Binding var errorMessage: String
    @Environment(\.dismiss) private var dismiss
    
    var isChangingPasscode: Bool {
        appState.settings.isPasscodeEnabled
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text(isChangingPasscode ? "Change Passcode" : "Set Up Passcode")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                VStack(spacing: 20) {
                    if isChangingPasscode {
                        SecureField("Current Passcode", text: $currentPasscode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    SecureField("New Passcode", text: $newPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirm Passcode", text: $confirmPasscode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(isChangingPasscode ? "Update Passcode" : "Set Passcode") {
                    savePasscode()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.blue : Color.gray)
                .cornerRadius(12)
                .disabled(!canSave)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        clearFields()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        let hasValidPasscodes = !newPasscode.isEmpty && newPasscode == confirmPasscode
        
        if isChangingPasscode {
            return hasValidPasscodes && appState.settings.validatePasscode(currentPasscode)
        } else {
            return hasValidPasscodes
        }
    }
    
    private func savePasscode() {
        guard canSave else { return }
        
        var settings = appState.settings
        settings.isPasscodeEnabled = true
        settings.passcode = newPasscode
        appState.updateSettings(settings)
        
        clearFields()
        dismiss()
    }
    
    private func clearFields() {
        newPasscode = ""
        confirmPasscode = ""
        currentPasscode = ""
    }
}

#Preview {
    SettingsView(appState: AppStateManager())
}
