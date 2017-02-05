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

    @NSManaged var organization: Any?
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
        guard let query = Member.query() else {
            completion(nil, nil)
            return
        }
        
        // because organization is a pointer, we have to use matchesQuery
        let orgQuery = PFQuery(className: "Organization")
        orgQuery.whereKey("objectId", equalTo: org.parseID)
        
        query.whereKey("organization", matchesQuery: orgQuery)
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
