//
//  Token.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/21/25.
//

import Foundation

struct Token: Identifiable, Codable {
    let id: UUID
    static let minutesPerToken = 15

    init(id: UUID = UUID()) {
        self.id = id
    }
}
