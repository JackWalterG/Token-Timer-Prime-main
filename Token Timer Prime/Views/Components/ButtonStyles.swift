//
//  ButtonStyles.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let isEnabled: Bool
    
    init(backgroundColor: Color = .blue, foregroundColor: Color = .white, isEnabled: Bool = true) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(isEnabled ? foregroundColor : .gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? backgroundColor : Color.gray.opacity(0.3))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let borderColor: Color
    let foregroundColor: Color
    let isEnabled: Bool
    
    init(borderColor: Color = .blue, foregroundColor: Color = .blue, isEnabled: Bool = true) {
        self.borderColor = borderColor
        self.foregroundColor = foregroundColor
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(isEnabled ? foregroundColor : .gray)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEnabled ? borderColor : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CircularButtonStyle: ButtonStyle {
    let backgroundColor: Color
    let size: CGFloat
    let isEnabled: Bool
    
    init(backgroundColor: Color = .blue, size: CGFloat = 50, isEnabled: Bool = true) {
        self.backgroundColor = backgroundColor
        self.size = size
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(isEnabled ? backgroundColor : Color.gray.opacity(0.3))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
