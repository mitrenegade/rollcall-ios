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

extension PracticesTableViewController: PracticeEditDelegate {
    public func didCreatePractice() {
        // query from web
        self.reloadPractices()
    }
    
    public func didEditPractice() {
        // just reload existing practices from data
        self.tableView.reloadData()
    }

}
