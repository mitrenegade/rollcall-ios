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

    func deletePracticeAt(indexPath: NSIndexPath) {
        guard let practices = Organization.current?.practices else {
            self.tableView.reloadData()
            return
        }
        let practice = practices[indexPath.row]
        practice.deleteInBackground { (success, error) in
            if success {
                Organization.queryForPractices(completion: { (practices, error) in
                    self.tableView.reloadData()
                    self.notify("practice:deleted", object: nil, userInfo: nil)
                    ParseLog.log(typeString: "PracticeDeleted", title: practice.objectId, message: nil, params: nil, error: nil)
                })
            }
            else {
                self.tableView.reloadData()
                ParseLog.log(typeString: "PracticeDeletionFailed", title: practice.objectId, message: nil, params: nil, error: error as? NSError)
            }
        }
    }

}
