//
//  Action.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Balizinha

enum AttendanceStatus: String {
    case notSignedUp
    case signedUp
    case notAttending
    case attended
    case noShow
}

class FirebaseAttendance: FirebaseBaseModel {
    var date: Date? {
        get {
            if let val = self.dict["date"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["date"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var status: AttendanceStatus? {
        get {
            if let statusString = dict["status"] as? String,
               let attendance = AttendanceStatus(rawValue: statusString) {
                return attendance
            } else {
                return .none
            }
        }
        set {
            update(key: "status", value: (newValue ?? .none))
        }
    }
    
    var organization: String? {
        // if user is nil, then it should be a system message
        get {
            return self.dict["organization"] as? String
        }
        set {
            self.dict["organization"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var user: String? {
        // if user is nil, then it should be a system message
        get {
            return self.dict["user"] as? String
        }
        set {
            self.dict["user"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var event: String? {
        // if user is nil, then it should be a system message
        get {
            return self.dict["event"] as? String
        }
        set {
            self.dict["event"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
}
