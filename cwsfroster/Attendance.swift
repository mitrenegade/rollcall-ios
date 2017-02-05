//
//  Attendance.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

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
