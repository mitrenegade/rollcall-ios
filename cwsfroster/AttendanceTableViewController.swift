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
    fileprivate var members: [FirebaseMember] = []

    var delegate: PracticeEditDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AttendanceCell.self, forCellReuseIdentifier: "AttendanceCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OnSiteSignupCell")

        self.listenFor("member:updated", action: #selector(reloadData), object: nil)
        self.listenFor("member:created", action: #selector(reloadData), object: nil)
        reloadData()
    }
    
    @IBAction func didClickDone(_ sender: AnyObject?) {
        self.delegate?.didEditPractice()
        self.navigationController?.dismiss(animated: true, completion: {
        })
    }
    
    @objc func reloadData() {
        OrganizationService.shared.members { [weak self] (members, error) in
            self?.members = members.sorted{
                guard let n1 = $0.name?.uppercased() else { return false }
                guard let n2 = $1.name?.uppercased() else { return true }
                return n1 < n2
            }
            self?.tableView.reloadData()
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
            cell.textLabel?.text = "Sign up new members"
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)
            
            guard let attendanceCell = cell as? AttendanceCell else { return cell }
            // Configure the cell...
            guard indexPath.row < members.count, let practice = currentPractice else { return cell }
            let member = members[indexPath.row]
            let attendance = practice.attendance(for: member.id)
            attendanceCell.configure(member: member, attendance: attendance, row: indexPath.row)
            return cell
        }
    }
}

// MARK: Table view delegate
extension AttendanceTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard self.currentPractice != nil else { return }

        if indexPath.section == 0 {
            guard let controller = UIStoryboard(name: "Events", bundle: nil)
                .instantiateViewController(identifier: "OnsiteSignupViewController") as? OnsiteSignupViewController else {
                    return
                }
            controller.practice = currentPractice
            navigationController?.pushViewController(controller, animated: true)
            LoggingService.log(type: "OnsiteSignupClicked")
            return
        }
        
        guard indexPath.row < members.count else { return }
        let member = members[indexPath.row]
        if currentPractice?.attendance(for: member.id) == .Present {
            currentPractice?.removeAttendance(for: member)
        } else {
            currentPractice?.addAttendance(for: member)
        }

        tableView.reloadData()
    }
}
