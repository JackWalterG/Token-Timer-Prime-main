//
//  ScheduledToken.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

struct ScheduledToken: Identifiable, Codable {
    let id: UUID
    var tokenCount: Int
    var scheduledDate: Date
    var title: String
    var notes: String?
    var recurrenceType: RecurrenceType
    var isActive: Bool
    let createdDate: Date
    var maxWalletTokens: Int?
    
    init(id: UUID = UUID(), tokenCount: Int, scheduledDate: Date, title: String, notes: String? = nil, recurrenceType: RecurrenceType = .daily, isActive: Bool = true, createdDate: Date = Date(), maxWalletTokens: Int? = nil) {
        self.id = id
        self.tokenCount = tokenCount
        self.scheduledDate = scheduledDate
        self.title = title
        self.notes = notes
        self.recurrenceType = recurrenceType
        self.isActive = isActive
        self.createdDate = createdDate
        self.maxWalletTokens = maxWalletTokens
    }
    
    var nextOccurrence: Date? {
        guard isActive else { return nil }
        
        let now = Date()
        var nextDate = scheduledDate
        
        // If it's in the future, return as is
        if nextDate > now {
            return nextDate
        }
        
        // Calculate next occurrence based on recurrence type
        let calendar = Calendar.current
        while nextDate <= now {
            switch recurrenceType {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            case .weekly:
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            case .monthly:
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            }
        }
        return nextDate
    }
    
    var isPastDue: Bool {
        return false // Recurring events are never past due, they just move to next occurrence
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
