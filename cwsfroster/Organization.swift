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
    @NSManaged var logoData: PFFile?
    
    var members: [Member]?
    var practices: [Practice]?
    var attendances: [Attendance]?
    
    // poweruser
    @NSManaged var leftPowerUserFeedback: NSNumber?
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
    
    
    class func queryForMembers(completion: @escaping (([Member]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Member.queryMembers(org: org, completion: { (results, error) in
            if let objects = results {
                org.members = objects
            }
            completion(results, error)
        })
    }
    
    class func queryForPractices(completion: @escaping (([Practice]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Practice.queryPractices(org: org, completion: { (results, error) in
            if let objects = results {
                org.practices = objects
            }
            completion(results, error)
        })
    }
    class func queryForAttendances(completion: @escaping (([Attendance]?, NSError?)->Void)) {
        guard let org = self.current else {
            completion(nil, nil)
            return
        }
        Attendance.queryAttendances(org: org, completion: { (results, error) in
            if let objects = results {
                org.attendances = objects
            }
            completion(results, error)
        })
    }
    
    // test
    class func withId(objectId: String, completion: @escaping ((_ result: PFObject?, _ error: NSError?) -> Void)) {
        let query = PFQuery(className: "Organization")
        query.whereKey("objectId", equalTo: objectId)
        query.findObjectsInBackground { (results, error) in
            if let objects = results, let org = objects.first {
                completion(org, nil)
            }
            else {
                completion(nil, error as? NSError)
            }
        }
    }
}

// MARK: Poweruser
fileprivate var powerUserPromptDeferDate: String = "powerUserPromptDeferDate"

extension Organization {
    var shouldPromptForPowerUserFeedback: Bool {
        guard let practices = self.practices, practices.count >= 5 else { return false }
        
        if let deferDate = UserDefaults.standard.value(forKey: powerUserPromptDeferDate) as? Date, deferDate.timeIntervalSinceNow > 0 {
            return false
        }
        
        guard let leftFeedback = self.leftPowerUserFeedback else { return true }
        return !leftFeedback.boolValue
    }
    
    func promptForPowerUserFeedback(from controller: UIViewController) {
        let alert = UIAlertController(title: "Congratulations, Power User", message: "Thanks for using RollCall! You have created at least 5 events. As a Power User, your feedback is really important to us. How can we improve?", preferredStyle: .alert)
        alert.addTextField { (textField) in
        }
        alert.addAction(UIAlertAction(title: "Send Feedback", style: .cancel, handler: { (action) in
            if let textField = alert.textFields?.first, let text = textField.text {
                ParseLog.log(typeString: "PowerUserFeedback", title: nil, message: text, params: nil, error: nil)
                self.leftPowerUserFeedback = NSNumber(booleanLiteral: true)
                self.saveInBackground(block: { (success, error) in
                    print("saved feedback \(success) \(error)")
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
        }))
        alert.addAction(UIAlertAction(title: "No Thanks", style: .default, handler: { (action) in
            let deferDate = Date(timeIntervalSinceNow: 3600*24*7*52)
            UserDefaults.standard.set(deferDate, forKey: powerUserPromptDeferDate)
            UserDefaults.standard.synchronize()
        }))
        controller.present(alert, animated: true, completion: nil)
    }
}
