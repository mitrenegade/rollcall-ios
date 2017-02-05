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

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Table view data source
extension AttendanceTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        guard let practice = self.practice else { return 0 }
//        return practice.attendances?.count ?? 0
        guard let members = Organization.current?.members else { return 0 }
        return members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)

        // Configure the cell...
        guard let members = Organization.current?.members, indexPath.row < members.count else { return cell }
        let member = members[indexPath.row]
        let nameLabel = cell.viewWithTag(2) as! UILabel
        nameLabel.text = member.name

        let unchecked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        unchecked.image = UIImage(named: "unchecked")
        cell.accessoryView = unchecked
        if let practice = self.practice, let attendance = practice.attendanceFor(member: member), let attended = attendance.attended, attended.intValue != AttendedStatus.None.rawValue {
            let checked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            checked.image = UIImage(named: "checked")
            cell.accessoryView = checked
        }
        
        return cell
    }
}

// MARK: Table view delegate
extension AttendanceTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let members = Organization.current?.members, indexPath.row < members.count else { return }
        let member = members[indexPath.row]
        guard let practice = self.practice else { return }
        
        if let attendance = practice.attendanceFor(member: member) {
            if let attended = attendance.attended, attended.intValue != AttendedStatus.None.rawValue {
                attendance.attended = NSNumber(value: AttendedStatus.None.rawValue)
            }
            else {
                attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
            }
            attendance.saveInBackground { (success, error) in
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
        else {
            self.saveNewAttendanceFor(member: member)
        }
    }
    
    func saveNewAttendanceFor(member: Member) {
        let attendance = Attendance()
        attendance.organization = Organization.current
        attendance.practice = self.practice
        attendance.member = member
        attendance.attended = NSNumber(value: AttendedStatus.Present.rawValue)
        attendance.date = self.practice?.date
        attendance.saveInBackground { (success, error) in
            Organization.current?.attendances?.append(attendance)
            self.tableView.reloadData()
        }
    }
}
