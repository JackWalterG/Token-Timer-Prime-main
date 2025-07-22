//
//  Wallet.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

struct Wallet: Codable {
    var totalTokens: Int
    
    init(totalTokens: Int = 0) {
        self.totalTokens = totalTokens
    }
    
    var availableTokens: Int {
        return totalTokens
    }
    
    mutating func addTokens(_ count: Int) {
        totalTokens += count
    }
    
    mutating func addTokensUpToMax(_ count: Int, maxTokens: Int) -> Int {
        guard maxTokens > 0 else {
            totalTokens += count
            return count
        }
        
        let availableSpace = max(0, maxTokens - totalTokens)
        let tokensToAdd = min(count, availableSpace)
        totalTokens += tokensToAdd
        return tokensToAdd
    }
    
    func canRedeem(_ count: Int) -> Bool {
        return totalTokens >= count
    }
    
    mutating func redeemTokens(_ count: Int) -> Bool {
        guard canRedeem(count) else { return false }
        totalTokens -= count
        return true
    }
}
