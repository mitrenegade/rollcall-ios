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

// MARK: - Power user feedback
extension PracticesTableViewController {
    func promptForPowerUserFeedback() {
        let alert = UIAlertController(title: "Congratulations, Power User", message: "Thanks for using RollCall! You have created at least 5 events. As a Power User, your feedback is really important to us. How can we improve?", preferredStyle: .alert)
        alert.addTextField { (textField) in
        }
        alert.addAction(UIAlertAction(title: "Send Feedback", style: .cancel, handler: { (action) in
            if let textField = alert.textFields?.first, let text = textField.text {
                ParseLog.log(typeString: "PowerUserFeedback", title: nil, message: text, params: nil, error: nil)
                Organization.current?.leftPowerUserFeedback = NSNumber(booleanLiteral: true)
                Organization.current?.saveInBackground(block: { (success, error) in
                    print("saved feedback \(success) \(error)")
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
            ParseLog.log(typeString: "PowerUserFeedbackLater", title: nil, message: nil, params: nil, error: nil)
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7*52)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
            ParseLog.log(typeString: "PowerUserFeedbackNever", title: nil, message: nil, params: nil, error: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
