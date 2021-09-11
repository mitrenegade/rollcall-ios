//
//  FirebaseUser.swift
//  rollcall
//
//  Created by Bobby Ren on 8/27/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Firebase
import Balizinha

class FirebaseUser: FirebaseBaseModel {
    static let none = FirebaseUser(key: "none", dict: [:])

    var subscription: SubscriptionProduct {
        get {
            guard let subscription = dict["subscription"] as? String,
                  let tier = Tier(rawValue: subscription) else {
                return .standard
            }
            return StoreKitManager.shared.subscriptionTier(for: tier) ?? .standard
        }
    }

    var userID: String {
        get {
            firebaseKey
        }
    }
}
