//
//  Action.swift
//  Balizinha
//
//  Created by Bobby Ren on 3/6/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Balizinha

// new UI: includes presignup
enum AttendanceStatus: String {
    case notSignedUp
    case signedUp
    case notAttending
    case attended
    case noShow
}

// old UI: attended or not
@objc enum AttendedStatus: Int {
    case None = 0
    case Present = 1
    case Freebie = 2
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
    
    var memberId: String? {
        get {
            return self.dict["memberId"] as? String
        }
        set {
            self.dict["memberId"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
    
    var eventId: String? {
        get {
            return self.dict["eventId"] as? String
        }
        set {
            self.dict["eventId"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
}
