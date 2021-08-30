//
//  SubscriptionTier.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

enum Tier: String, Equatable, Codable {
    case standard
    case plus
    case premium
}

struct SubscriptionTier: Codable, Equatable {
    let name: Tier
    let productId: String

    static let standard = SubscriptionTier(name: .standard, productId: "")
}
