//
//  Attendance.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class Attendance: PFObject {

    @NSManaged var date: Date?
    @NSManaged var attended: NSNumber?
    
    @NSManaged var organization: Organization?
    @NSManaged var member: Member?
    @NSManaged var practice: Practice?
}

extension Attendance: PFSubclassing {
    static func parseClassName() -> String {
        return "Attendance"
    }
}

extension Attendance {
    class func queryAttendances(org: Organization, completion: @escaping ((_ results: [Attendance]?, _ error: NSError?) -> Void)) {
        guard let query = Attendance.query() else {
            completion(nil, nil)
            return
        }
        
        // because organization is a pointer, we have to use matchesQuery
        let orgQuery = PFQuery(className: "Organization")
        orgQuery.whereKey("objectId", equalTo: org.objectId!)
        
        query.whereKey("organization", matchesQuery: orgQuery)
        query.findObjectsInBackground { (results, error) in
            if let objects = results as? [Attendance] {
                completion(objects, nil)
            }
            else {
                completion(nil, error as? NSError)
            }
        }
    }
}

// MARK: Offline
extension Attendance {
    class func offlineAttendances() -> [Attendance] {
        guard let practice = Organization.current?.practices?.first else {
            print("Offline attendances failed")
            return []
        }
        guard let members = Organization.current?.members else {
            print("Offline attendances failed")
            return []
        }
        var attendances: [Attendance] = []
        for member in members {
            let attendance = Attendance()
            attendance.organization = Organization.current
            attendance.practice = practice
            attendance.member = member
            attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
            attendance.date = practice.date
            attendances.append(attendance)
        }
        return attendances
    }
}
