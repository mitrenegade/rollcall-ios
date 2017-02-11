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
                attendance.saveInBackground()
            }
            // because didCreatePractice does not reload attendances
            Organization.current?.saveInBackground()
            
            practice?.saveInBackground(block: { (success, error) in
                self.delegate?.didCreatePractice()
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
//        guard let practice = self.practice else { return 0 }
//        return practice.attendances?.count ?? 0
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
        
        if indexPath.section == 0 {
            self.performSegue(withIdentifier: "ToOnSiteSignup", sender: nil)
            return
        }
        
        guard let members = Organization.current?.members, indexPath.row < members.count else { return }
        let member = members[indexPath.row]
        guard let practice = self.practice else { return }
        
        if let attendance = practice.attendanceFor(member: member) {
            self.toggleAttendance(attendance: attendance)
            attendance.saveInBackground { (success, error) in
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
        else if let attendance = newAttendances[member] {
            self.toggleAttendance(attendance: attendance)
            newAttendances[member] = attendance
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        else {
            self.saveNewAttendanceFor(member: member, indexPath: indexPath)
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
    
    func saveNewAttendanceFor(member: Member, indexPath: IndexPath) {
        let attendance = Attendance()
        attendance.organization = Organization.current
        attendance.practice = self.practice
        attendance.member = member
        attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
        attendance.date = self.practice?.date
        if self.isNewPractice {
            newAttendances[member] = attendance
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        else {
            attendance.saveInBackground { (success, error) in
                DispatchQueue.main.async {
                    Organization.current?.attendances?.append(attendance)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
}
