//
//  AttendanceTableViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class AttendanceTableViewController: UITableViewController {

    var currentPractice: FirebaseEvent?
    var newPracticeDict: [String: Any] = [:]
    fileprivate var attendees: [String] = []
    fileprivate var members: [FirebaseMember] = []

    var delegate: PracticeEditDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenFor("member:updated", action: #selector(reloadData), object: nil)
        reloadData()
    }
    
    @IBAction func didClickDone(_ sender: AnyObject?) {
        self.delegate?.didEditPractice()
        self.navigationController?.dismiss(animated: true, completion: {
        })
            // BOBBY TODO
//            for (_, attendance) in newAttendances {
//                attendance.organization?.attendances?.append(attendance)
//                attendance.saveInBackground(block: { (success, error) in
//                    if success {
//                        ParseLog.log(typeString: "AttendanceCreated", title: attendance.objectId, message: nil, params: nil, error: nil)
//                    }
//                })
//            }
    }
    
    func reloadData() {
        guard let practice = currentPractice else { return }
        self.attendees = practice.attendees
        OrganizationService.shared.members { [weak self] (members, error) in
            self?.members = members.sorted{
                guard let n1 = $0.name?.uppercased() else { return false }
                guard let n2 = $1.name?.uppercased() else { return true }
                return n1 < n2
            }
            self?.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToOnSiteSignup" {
            if let controller = segue.destination as? OnsiteSignupViewController {
                // BOBBY TODO
//                controller.practice = currentPractice
            }
        }
    }
}

// MARK: - Table view data source
extension AttendanceTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OnSiteSignupCell", for: indexPath)
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)
            
            guard let attendanceCell = cell as? AttendanceCell else { return cell }
            // Configure the cell...
            guard indexPath.row < members.count else { return cell }
            let member = members[indexPath.row]
            let attendance = attendees.contains(member.id) ? AttendedStatus.Present : AttendedStatus.None
            attendanceCell.configure(member: member, attendance: attendance, row: indexPath.row)
            return cell
        }
    }
}

// MARK: Table view delegate
extension AttendanceTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let practice = self.currentPractice else { return }

        if indexPath.section == 0 {
            // BOBBY TODO
//            practice.saveInBackground(block: { (success, error) in
//                DispatchQueue.main.async {
//                    if success {
//                        if self.isNewPractice {
//                            Organization.current?.practices?.insert(practice, at: 0)
//                            self.isNewPractice = false
//                        }
//                        self.delegate?.didEditPractice()
//                        self.performSegue(withIdentifier: "ToOnSiteSignup", sender: nil)
//
//                        ParseLog.log(typeString: "OnsiteSignupClicked", title: nil, message: nil, params: nil, error: nil)
//                    }
//                    else {
//                        self.simpleAlert("Could not go to onsite signup", message: "There was an error creating this event so we could not start onsite signups.")
//                    }
//                }
//            })
            return
        }
        
        guard indexPath.row < members.count else { return }
        let member = members[indexPath.row]
        
        // BOBBY TODO
//        if let attendance = currentPractice.attendanceFor(member: member) {
//            self.toggleAttendance(attendance: attendance)
//            attendance.saveInBackground { (success, error) in
//                self.tableView.reloadRows(at: [indexPath], with: .automatic)
//                ParseLog.log(typeString: "AttendanceSaved", title: attendance.objectId, message: nil, params: nil, error: nil)
//            }
//        }
//        else if let attendance = newAttendances[member] {
//            self.toggleAttendance(attendance: attendance)
//            newAttendances[member] = attendance
//            self.tableView.reloadRows(at: [indexPath], with: .automatic)
//        }
//        else {
//            if self.isNewPractice {
//                Attendance.saveNewAttendanceFor(member: member, practice: currentPractice, saveToParse: false, completion: { (attendance, error) in
//                    ParseLog.log(typeString: "AttendanceCreated", title: attendance?.objectId, message: nil, params: nil, error: nil)
//                    self.newAttendances[member] = attendance
//                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
//                })
//            }
//            else {
//                Attendance.saveNewAttendanceFor(member: member, practice: currentPractice, saveToParse: true, completion: { (attendance, error) in
//                    ParseLog.log(typeString: "AttendanceCreated", title: attendance?.objectId, message: nil, params: nil, error: nil)
//                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
//                })
//            }
//        }
    }
    
    func toggleAttendance(attendance: Attendance) {
        if let attended = attendance.attended, attended.intValue != AttendedStatus.None.rawValue {
            attendance.attended = NSNumber(value: AttendedStatus.None.rawValue)
        }
        else {
            attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
        }
    }
    
}
