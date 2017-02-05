//
//  MembersTableViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

var members: [Member]? // temporary replacement of persistence
extension MembersTableViewController {
    func allMembers() -> [Member] {
        if members != nil {
            return members!
        }
        Member.queryMembers(org: Organization.current()!) { results, error in
            if let mem = results {
                members = mem
            }
            self.reloadMembers()
        }
        return []
    }
}
