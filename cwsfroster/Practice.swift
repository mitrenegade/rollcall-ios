//
//  Practice.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class Practice: PFObject {

    @NSManaged var title: String?
    @NSManaged var date: Date?
    @NSManaged var notes: String?
    @NSManaged var details: String?
    
    @NSManaged var organization: Organization?
}

extension Practice: PFSubclassing {
    static func parseClassName() -> String {
        return "Practice"
    }
}

extension Practice {
    class func queryPractices(org: Organization, completion: @escaping ((_ results: [Practice]?, _ error: NSError?) -> Void)) {
        guard !OFFLINE_MODE else {
            completion(self.offlinePractices(), nil)
            return
        }
        
        guard let query = Practice.query() else {
            completion(nil, nil)
            return
        }
        
        // because organization is a pointer, we have to use matchesQuery
        let orgQuery = PFQuery(className: "Organization")
        orgQuery.whereKey("objectId", equalTo: org.objectId!)
        
        query.whereKey("organization", matchesQuery: orgQuery)
        query.addDescendingOrder("title")
        query.findObjectsInBackground { (results, error) in
            if let objects = results as? [Practice] {
                completion(objects, nil)
            }
            else {
                completion(nil, error as? NSError)
            }
        }
    }

    var attendances: [Attendance]? {
        guard let allAttendances = Organization.current?.attendances else { return [] }
        let myAttendances = allAttendances.filter { (a) -> Bool in
            if a.practice?.objectId == self.objectId, a.attended?.intValue ?? 0 != AttendedStatus.None.rawValue {
                return true
            }
            return false
        }
        return myAttendances
    }
    
    func attendanceFor(member: Member) -> Attendance? {
        guard let allAttendances = Organization.current?.attendances else { return nil }
        let myAttendances = allAttendances.filter { (a) -> Bool in
            if a.practice?.objectId == self.objectId, a.member?.objectId == member.objectId {
                return true
            }
            return false
        }
        return myAttendances.first
    }
}

// MARK: Offline
extension Practice {
    class func offlinePractices() -> [Practice] {
        let eventParams = ["title": "Flight school", "date": Date(), "notes": "Being in the air", "details": ""] as [String : Any]
        let event = Practice(className: "Practice", dictionary: eventParams)
        return [event]
    }
}

// MARK: Date utils
extension Practice {
    func dateOnly() -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        guard let date = self.date else { return nil }
        let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
        if let componentsBasedDate = calendar.date(from: dateComponents) {
            return componentsBasedDate
        }
        return nil
    }
}

