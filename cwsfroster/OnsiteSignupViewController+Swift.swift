//
//  OnsiteSignupViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/11/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

extension OnsiteSignupViewController {
    func didClickSignup(_ sender: AnyObject?) {
        guard let name = inputName.text, !name.isEmpty else {
            self.simpleAlert("Please enter a name", message: nil)
            return
        }
        
        if let email = inputEmail.text, !email.isEmpty && !email.isValidEmail() {
            self.simpleAlert("Please enter a valid email", message: nil)
            return
        }
        
        let member = Member()
        member.organization = Organization.current
        member.name = name
        member.email = inputEmail.text
        
        if let photo = self.addedPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
            member.photo = PFFile(data:data)
        }
        
        ParseLog.log(typeString: "OnsiteSignup", title: nil, message: nil, params: ["photo": self.addedPhoto != nil], error: nil)
        self.notify("member:updated", object: nil, userInfo: nil)
        
        member.saveInBackground { (result, error) in
            Organization.current?.members?.insert(member, at: 0)
        }
        
        self.saveNewAttendanceFor(member: member, practice: self.practice) { (attendance, error) in
            if let error = error {
                self.simpleAlert("Could not sign up user", message: "There was an error adding \(member.name) to this event. Please add them manually by editing event attendees")
                return
            }

            self.addedAttendees.insert(member, at: 0)
            self.labelAttendanceCount.text = "New attendees: \(self.addedAttendees.count)"
            
            self.labelWelcome.alpha = 1
            self.labelWelcome.text = "Welcome \(member.name ?? "")"
            
            UIView.animate(withDuration: 0.25, delay: 2, options: UIViewAnimationOptions.curveLinear, animations: {
                self.labelWelcome.alpha = 0
            }, completion: nil)
        }
    }

    func saveNewAttendanceFor(member: Member, practice: Practice, completion: @escaping ((Attendance?, NSError?)->Void)) {
        let attendance = Attendance()
        attendance.organization = Organization.current
        attendance.practice = practice
        attendance.member = member
        attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
        attendance.saveInBackground { (success, error) in
            if let error = error as? NSError {
                completion(nil, error)
            }
            else {
                Organization.current?.attendances?.insert(attendance, at: 0)
                completion(attendance, nil)
            }
        }
    }
    
}
