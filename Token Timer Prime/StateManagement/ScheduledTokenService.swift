//
//  ScheduledTokenService.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import Foundation

@MainActor
class ScheduledTokenService: ObservableObject {
    @Published var scheduledTokens: [ScheduledToken] = []
    
    weak var delegate: ScheduledTokenServiceDelegate?
    
    // MARK: - Public Methods
    
    func processScheduledTokens() {
        var changed = false
        
        for i in 0..<scheduledTokens.count {
            var scheduled = scheduledTokens[i]
            guard scheduled.isActive else { continue }
            
            let nextOccurrenceDate = scheduled.scheduledDate
            var tokensToAddThisTime = 0

            var tempNextOccurrenceDate = nextOccurrenceDate
            while tempNextOccurrenceDate <= Date() {
                tokensToAddThisTime += scheduled.tokenCount
                
                let nextDate: Date?
                switch scheduled.recurrenceType {
                case .daily:
                    nextDate = Calendar.current.date(byAdding: .day, value: 1, to: tempNextOccurrenceDate)
                case .weekly:
                    nextDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: tempNextOccurrenceDate)
                case .monthly:
                    nextDate = Calendar.current.date(byAdding: .month, value: 1, to: tempNextOccurrenceDate)
                }
                
                if let next = nextDate {
                    tempNextOccurrenceDate = next
                } else {
                    break
                }
            }
            
            if tokensToAddThisTime > 0 {
                scheduled.scheduledDate = tempNextOccurrenceDate
                changed = true
                
                // Add tokens to wallet through delegate
                if let maxTokens = scheduled.maxWalletTokens {
                    let currentTokens = delegate?.getCurrentWalletTokens() ?? 0
                    let canAdd = max(0, maxTokens - currentTokens)
                    let actualTokensToAdd = min(tokensToAddThisTime, canAdd)
                    if actualTokensToAdd > 0 {
                        delegate?.addTokensToWallet(actualTokensToAdd)
                    }
                } else {
                    delegate?.addTokensToWallet(tokensToAddThisTime)
                }
            }
            
            scheduledTokens[i] = scheduled
        }
        
        if changed {
            delegate?.shouldSaveScheduledTokens()
        }
    }
    
    func addScheduledToken(_ scheduledToken: ScheduledToken) {
        scheduledTokens.append(scheduledToken)
        delegate?.shouldSaveScheduledTokens()
    }
    
    func updateScheduledToken(_ scheduledToken: ScheduledToken) {
        if let index = scheduledTokens.firstIndex(where: { $0.id == scheduledToken.id }) {
            scheduledTokens[index] = scheduledToken
            delegate?.shouldSaveScheduledTokens()
        }
    }
    
    func removeScheduledToken(_ id: UUID) {
        scheduledTokens.removeAll { $0.id == id }
        delegate?.shouldSaveScheduledTokens()
    }
    
    func toggleScheduledToken(_ id: UUID) {
        if let index = scheduledTokens.firstIndex(where: { $0.id == id }) {
            scheduledTokens[index].isActive.toggle()
            delegate?.shouldSaveScheduledTokens()
        }
    }
    
    func setScheduledTokens(_ tokens: [ScheduledToken]) {
        scheduledTokens = tokens
    }
}

// MARK: - Scheduled Token Service Delegate

@MainActor
protocol ScheduledTokenServiceDelegate: AnyObject {
    func addTokensToWallet(_ count: Int)
    func getCurrentWalletTokens() -> Int
    func shouldSaveScheduledTokens()
}
