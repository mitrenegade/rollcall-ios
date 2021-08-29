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
    var subscription: SubscriptionTier {
        get {
            guard let subscription = dict["subscription"] as? String else {
                return .standard
            }
            return SubscriptionTier(rawValue: subscription) ?? .standard
        }
    }

    var userID: String {
        get {
            firebaseKey
        }
    }
}
