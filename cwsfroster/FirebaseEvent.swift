//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Balizinha
import Firebase

fileprivate let formatter = DateFormatter()

class FirebaseEvent: FirebaseBaseModel {

    var title: String? {
        get {
            return self.dict["title"] as? String
        }
        set {
            update(key: "title", value: newValue)
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
            update(key: "date", value: newValue?.timeIntervalSince1970)
        }
    }

    var notes: String? {
        get {
            return self.dict["notes"] as? String
        }
        set {
            update(key: "notes", value: newValue)
        }
        
    }
    
    var details: String? {
        get {
            return self.dict["details"] as? String
        }
        set {
            update(key: "details", value: newValue)
        }
    }

    var organization: String? {
        get {
            return self.dict["organization"] as? String
        }
        set {
            update(key: "organization", value: newValue)
        }
    }

    var cost: Double? {
        get {
            return self.dict["cost"] as? Double
        }
        set {
            update(key: "cost", value: newValue)
        }
    }
    
    fileprivate var attendeesReadWriteQueue = DispatchQueue(label: "attendees")
    var attendees: [String] {
        get {
            var result: [String] = []
            attendeesReadWriteQueue.sync {
                let attendances = self.dict["attendees"] as? [String: Bool] ?? [:]
                result = attendances.compactMap({ (key, val) -> String? in
                    if val {
                        return key
                    }
                    return nil
                })
            }
            return result
        }
        set {
            var newAttendees: [String: Bool] = [:]
            for memberId in newValue {
                newAttendees[memberId] = true
            }
            update(key: "attendees", value: newAttendees)
        }
    }

    // Old attendance format where the memberId is just stored as an array in the event
    func attended(for userId: String) -> AttendedStatus {
        if attendees.contains(userId) {
            return .Present
        }
        return .None
    }

    // MARK: - Old attendance that has userId: bool
    func addAttendance(for memberId: String) {
        var attendances = attendees
        if !attendances.contains(memberId) {
            attendeesReadWriteQueue.sync {
                attendances.append(memberId)
                attendees = attendances
            }
        }
    }

    func removeAttendance(for memberId: String) {
        var attendances = attendees
        if attendances.contains(memberId),
           let index = attendees.firstIndex(of: memberId) {
            attendeesReadWriteQueue.sync {
                attendances.remove(at: index)
                attendees = attendances
            }
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
    
    @objc func dateOnly() -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        guard let date = self.date else { return nil }
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
        if let componentsBasedDate = calendar.date(from: dateComponents) {
            return componentsBasedDate
        }
        return nil
    }
}

