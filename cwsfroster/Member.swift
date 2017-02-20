//
//  Member.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class Member: PFObject {
    @NSManaged var name: String?
    @NSManaged var email: String?
    @NSManaged var notes: String?
    @NSManaged var photo: PFFile?
    @NSManaged var status: NSNumber?

    @NSManaged var organization: Organization?
}

extension Member: PFSubclassing {
    static func parseClassName() -> String {
        return "Member"
    }
}

extension Member {
    var isInactive: Bool {
        return status?.intValue == MemberStatus.Inactive.rawValue
    }
    
    class func queryMembers(org: Organization, completion: @escaping ((_ members: [Member]?, _ error: NSError?) -> Void)) {
        guard !OFFLINE_MODE else {
            completion(self.offlineMembers(), nil)
            return
        }
        guard let query = Member.query() else {
            completion(nil, nil)
            return
        }
        
        // because organization is a pointer, we have to use matchesQuery
        let orgQuery = PFQuery(className: "Organization")
        orgQuery.whereKey("objectId", equalTo: org.objectId!)
        
        query.whereKey("organization", matchesQuery: orgQuery)
        query.addAscendingOrder("name")
        query.findObjectsInBackground { (results, error) in
            if let members = results as? [Member] {
                completion(members, nil)
            }
            else {
                completion(nil, error as? NSError)
            }
        }
    }
}

// MARK: Offline
extension Member {
    class func offlineMembers() -> [Member] {
        let member1 = Member(className: "Member", dictionary: ["name": "Chris", "email": "chris@gmail.com", "status": NSNumber(value: MemberStatus.Active.rawValue)])
        let member2 = Member(className: "Member", dictionary: ["name": "Bob", "email": "bob@gmail.com", "status": NSNumber(value: MemberStatus.Active.rawValue)])
        let member3 = Member(className: "Member", dictionary: ["name": "Kyle", "email": "kyle@gmail.com", "status": NSNumber(value: MemberStatus.Active.rawValue)])
        return [member1, member2, member3]
    }
}
