//
//  PracticesTableViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit

var _practices: [FirebaseEvent]?
extension PracticesTableViewController: UITableViewDataSource {
    var practices: [FirebaseEvent] {
        return _practices ?? []
    }
    
    open override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return practices.count
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PracticeCell", for: indexPath)

        // Configure the cell...
        let practice = self.practice(for: indexPath.row)
        cell.textLabel?.text = practice?.name
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        cell.textLabel?.textColor = .black
        
        cell.detailTextLabel?.text = practice?.details
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
        cell.detailTextLabel?.textColor = UIColor.darkGray

        return cell
    }

    open override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    open override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        self.deletePracticeAt(indexPath: indexPath as NSIndexPath)
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "EventListToDetail", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
extension PracticesTableViewController {
    func reloadPractices() {
        OrganizationService.shared.events { [weak self] (events, error) in
            _practices = events
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    func practice(for row: Int) -> FirebaseEvent? {
        return practices[row]
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
