//
//  ToastView.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success, warning, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(type.color)
        .cornerRadius(12)
        .shadow(color: type.color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// Toast Manager for showing toasts
@MainActor
class ToastManager: ObservableObject {
    @Published var toast: (message: String, type: ToastView.ToastType)? = nil
    @Published var showToast = false
    
    func show(_ message: String, type: ToastView.ToastType) {
        toast = (message, type)
        showToast = true
        
        // Auto dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.dismiss()
        }
    }
    
    func dismiss() {
        showToast = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.toast = nil
        }
    }
}

// Toast modifier for easy use
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if toastManager.showToast, let toast = toastManager.toast {
                        VStack {
                            Spacer()
                            ToastView(message: toast.message, type: toast.type)
                                .padding(.horizontal)
                                .padding(.bottom, 100)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: toastManager.showToast)
                    }
                }
            )
    }
}

extension View {
    func toast(manager: ToastManager) -> some View {
        self.modifier(ToastModifier(toastManager: manager))
    }
}
