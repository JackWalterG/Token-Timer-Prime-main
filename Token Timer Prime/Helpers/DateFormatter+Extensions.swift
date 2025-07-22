//
//  DateFormatter+Extensions.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

extension DateFormatter {
    static let mediumDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let weekKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"
        return formatter
    }()
}

extension Date {
    func formattedMedium() -> String {
        return DateFormatter.mediumDateTime.string(from: self)
    }
    
    func formattedShortTime() -> String {
        return DateFormatter.shortTime.string(from: self)
    }
    
    func dayKey() -> String {
        return DateFormatter.dayKey.string(from: self)
    }
    
    func weekKey() -> String {
        return DateFormatter.weekKey.string(from: self)
    }
}
