//
//  AttendanceTableViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class AttendanceTableViewController: UITableViewController {

    var isNewPractice: Bool = false
    var practice: Practice?
    var newAttendances: [Member: Attendance] = [Member: Attendance]()

    var delegate: PracticeEditDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !isNewPractice {
            // all changes to attendances are automatically saved
            self.navigationItem.rightBarButtonItem = nil
        }
        
        self.listenFor("member:updated", action: #selector(reloadData), object: nil)
    }
    
    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didClickSave(_ sender: AnyObject?) {
        if isNewPractice {
            for (_, attendance) in newAttendances {
                attendance.organization?.attendances?.append(attendance)
                attendance.saveInBackground(block: { (success, error) in
                    if success {
                        ParseLog.log(typeString: "AttendanceCreated", title: attendance.objectId, message: nil, params: nil, error: nil)
                    }
                })
            }
            // because didCreatePractice does not reload attendances
            //Organization.current?.saveInBackground()
            
            practice?.saveInBackground(block: { (success, error) in
                if success {
                    ParseLog.log(typeString: "PracticeCreated", title: self.practice?.objectId, message: nil, params: nil, error: nil)
                    self.delegate?.didCreatePractice()
                }
                self.navigationController?.dismiss(animated: true, completion: {
                })
            })
        }
        else {
            self.delegate?.didEditPractice()
            self.navigationController?.dismiss(animated: true, completion: {
            })
        }
    }
    
    func reloadData() {
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToOnSiteSignup" {
            if let controller = segue.destination as? OnsiteSignupViewController {
                controller.practice = self.practice
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
        guard let members = Organization.current?.members else { return 0 }
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
            guard let members = Organization.current?.members, indexPath.row < members.count else { return cell }
            let member = members[indexPath.row]
            attendanceCell.configure(member: member, practice: self.practice, newAttendance: newAttendances[member], row: indexPath.row)
            return cell
        }
    }
}

// MARK: Table view delegate
extension AttendanceTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let practice = self.practice else { return }

        if indexPath.section == 0 {
            practice.saveInBackground(block: { (success, error) in
                DispatchQueue.main.async {
                    if success {
                        Organization.current?.practices?.insert(practice, at: 0)
                        self.delegate?.didEditPractice()
                        self.performSegue(withIdentifier: "ToOnSiteSignup", sender: nil)
                        
                        ParseLog.log(typeString: "OnsiteSignupClicked", title: nil, message: nil, params: nil, error: nil)
                    }
                    else {
                        self.simpleAlert("Could not go to onsite signup", message: "There was an error creating this event so we could not start onsite signups.")
                    }
                }
            })
            return
        }
        
        guard let members = Organization.current?.members, indexPath.row < members.count else { return }
        let member = members[indexPath.row]
        
        if let attendance = practice.attendanceFor(member: member) {
            self.toggleAttendance(attendance: attendance)
            attendance.saveInBackground { (success, error) in
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                ParseLog.log(typeString: "AttendanceSaved", title: attendance.objectId, message: nil, params: nil, error: nil)
            }
        }
        else if let attendance = newAttendances[member] {
            self.toggleAttendance(attendance: attendance)
            newAttendances[member] = attendance
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        else {
            if self.isNewPractice {
                Attendance.saveNewAttendanceFor(member: member, practice: practice, saveToParse: false, completion: { (attendance, error) in
                    ParseLog.log(typeString: "AttendanceCreated", title: attendance?.objectId, message: nil, params: nil, error: nil)
                    self.newAttendances[member] = attendance
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                })
            }
            else {
                Attendance.saveNewAttendanceFor(member: member, practice: practice, saveToParse: true, completion: { (attendance, error) in
                    ParseLog.log(typeString: "AttendanceCreated", title: attendance?.objectId, message: nil, params: nil, error: nil)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                })
            }
        }
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
