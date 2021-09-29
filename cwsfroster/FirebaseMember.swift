//
//  Player.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Balizinha
import Firebase

class FirebaseMember: FirebaseBaseModel {
    enum Platform: String {
        case ios
        case android
    }
    
    var photo: UIImage?

    var name: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["name"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var email: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["email"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["email"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var notes: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["notes"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["notes"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var photoUrl: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["photoUrl"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["photoUrl"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var organization: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["organization"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["organization"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var status: String? {
        get {
            guard let dict = self.dict else { return nil }
            if let val = dict["status"] as? String {
                return val
            }
            return nil
        }
        set {
            self.dict["status"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var isInactive: Bool {
        return status != "active"
    }
    
    var displayName: String {
        return name ?? email ?? "Anon"
    }
}

extension FirebaseMember: Comparable {
    static func < (lhs: FirebaseMember, rhs: FirebaseMember) -> Bool {
        guard let n1 = lhs.name?.uppercased() else { return false }
        guard let n2 = rhs.name?.uppercased() else { return true }
        return n1 < n2
    }
}
