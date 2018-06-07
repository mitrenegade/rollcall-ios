//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate let formatter = DateFormatter()

class FirebaseEvent: FirebaseBaseModel {
//    var service = EventService.shared
    
    var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

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

    var notes: String? {
        get {
            return self.dict["notes"] as? String
        }
        set {
            self.dict["notes"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
    
    var details: String? {
        get {
            return self.dict["details"] as? String
        }
        set {
            self.dict["details"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var organization: String? {
        get {
            return self.dict["organization"] as? String
        }
        set {
            self.dict["organization"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }
}

// Utils
extension FirebaseEvent {
    func dateString(_ date: Date) -> String {
        //return "\((date as NSDate).day()) \(months[(date as NSDate).month() - 1]) \((date as NSDate).year())"
        return date.dateStringForPicker()
    }
    
    func timeString(_ date: Date) -> String {
        /*
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: date)
        return "\(time)"
        */
        return date.timeStringForPicker()
    }
    
    func dateOnly() -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        guard let date = self.date else { return nil }
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
        if let componentsBasedDate = calendar.date(from: dateComponents) {
            return componentsBasedDate
        }
        return nil
    }
}

