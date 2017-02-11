//
//  Organization.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

var _currentOrganization: Organization?

class Organization: PFObject {
    @NSManaged var name: String?
    @NSManaged var logoData: Data?
    
    var members: [Member]?
    var practices: [Practice]?
    var attendances: [Attendance]?
}

extension Organization: PFSubclassing {
    static func parseClassName() -> String {
        return "Organization"
    }
}

extension Organization {
    static var current: Organization? {
        get {
            return _currentOrganization
        }
        set {
            _currentOrganization = newValue
        }
    }
    
    class func reset() {
        _currentOrganization = nil
    }
    
    
    class func queryForMembers(completion: @escaping (([Member]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Member.queryMembers(org: org, completion: { (results, error) in
            if let objects = results {
                org.members = objects
            }
            completion(results, error)
        })
    }
    
    class func queryForPractices(completion: @escaping (([Practice]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Practice.queryPractices(org: org, completion: { (results, error) in
            if let objects = results {
                org.practices = objects
            }
            completion(results, error)
        })
    }
    class func queryForAttendances(completion: @escaping (([Attendance]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Attendance.queryAttendances(org: org, completion: { (results, error) in
            if let objects = results {
                org.attendances = objects
            }
            completion(results, error)
        })
    }
    
    // test
    class func withId(objectId: String, completion: @escaping ((_ result: PFObject?, _ error: NSError?) -> Void)) {
        let query = PFQuery(className: "Organization")
        query.whereKey("objectId", equalTo: objectId)
        query.findObjectsInBackground { (results, error) in
            if let objects = results, let org = objects.first {
                completion(org, nil)
            }
            else {
                completion(nil, error as? NSError)
            }
        }
    }
}
