//
//  SubscriptionProduct.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

enum Tier: String, Codable, Hashable, Comparable, CaseIterable {
    case standard
    case plus
    case premium

    private var level: Int {
        switch self {
        case .standard:
            return 0
        case .plus:
            return 1
        case .premium:
            return 2
        }
    }

    static func < (lhs: Tier, rhs: Tier) -> Bool {
        lhs.level < rhs.level
    }

}

struct SubscriptionProduct: Codable, Hashable {
    let id: Int // also the order
    let tier: Tier
    let productId: String

    static let standard = SubscriptionProduct(id: 0, tier: .standard, productId: "")

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

// MARK: - features
extension SubscriptionProduct {
    var hasEventReminders: Bool {
        tier > .standard
    }
}
