//
//  PracticesTableViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit

extension PracticesTableViewController {
    func reloadPractices() {
        Organization .queryForPractices { (results, error) in
            self.tableView.reloadData()
        }
    }
}
