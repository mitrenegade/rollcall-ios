//
//  FirebaseUser.swift
//  rollcall
//
//  Created by Bobby Ren on 8/27/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation
import Firebase

class FirebaseUser: FirebaseBaseModel {
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
