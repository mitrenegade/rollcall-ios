//
//  Practice.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

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
