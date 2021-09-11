//
//  League.swift
//  Balizinha Admin
//
//  Created by Bobby Ren on 4/9/18.
//  Copyright © 2018 RenderApps LLC. All rights reserved.
//

import Firebase
import Balizinha

class FirebaseOrganization: FirebaseBaseModel {
    var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var photoUrl: String? {
        get {
            return self.dict["photoUrl"] as? String
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var leftPowerUserFeedback: Bool {
        get {
            return self.dict["leftPowerUserFeedback"] as? Bool ?? false
        }
        set {
            self.dict["leftPowerUserFeedback"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

}
