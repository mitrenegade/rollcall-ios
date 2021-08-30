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
    let tier: Tier
    let productId: String

    static let standard = SubscriptionTier(tier: .standard, productId: "")

    var description: String {
        switch self.tier {
        case .standard:
            return "Basic member and event management tools for a single organization."
        case .plus:
            return "Advanced membership management including member pre-signup, payment, and vaccination status."
        case .premium:
            return "Advanced event management including recurring events and statistics. Multiple organizations."
        }
    }
}
