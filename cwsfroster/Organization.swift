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
}
