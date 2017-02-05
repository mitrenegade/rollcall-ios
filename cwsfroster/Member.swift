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
}
