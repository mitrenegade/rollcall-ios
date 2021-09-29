//
//  AttendanceTableViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

class AttendanceTableViewController: UITableViewController {

    private enum Section {
        case onsiteSignup
        case attendances
        case members
    }

    private let sections: [Section]

    private let event: FirebaseEvent?

    private let attendanceService: AttendanceService?

    private var members: [FirebaseMember] = []

    // MARK: - Attendance status, as an array of tuples. Sorted by member name

    private var attendances: [Attendance] = []

    private weak var delegate: PracticeEditDelegate?

//    private let attendanceService: AttendanceService?

    init(event: FirebaseEvent?, delegate: PracticeEditDelegate? = nil) {
        self.event = event
        self.delegate = delegate

        if FeatureManager.shared.hasPrepopulateAttendance {
            sections = [.onsiteSignup, .attendances, .members]
        } else {
            sections = [.onsiteSignup, .members]
        }

        if let event = event {
            attendanceService = AttendanceService(event: event)
        } else {
            attendanceService = nil
        }

        super.init(nibName: nil, bundle: nil)
    }

    private let disposeBag = DisposeBag()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(AttendanceCell.self, forCellReuseIdentifier: "AttendanceCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "OnSiteSignupCell")

        setupBindings()
    }
    
    @IBAction func didClickDone(_ sender: AnyObject?) {
        self.delegate?.didEditPractice()
        self.navigationController?.dismiss(animated: true, completion: {
        })
    }
    
    private func setupBindings() {
        // don't need member create and update notifications because members will change
//        let updatedObservable = NotificationCenter.default.rx.notification(Notification.Name("member:updated"))
//        let createdObservable = NotificationCenter.default.rx.notification(Notification.Name("member:updated"))
//        let membersObservable = OrganizationService.shared.membersObservable

        OrganizationService.shared.members { [weak self] result in
            switch result {
            case .success(let members):
                self?.members = members.sorted{
                    guard let n1 = $0.name?.uppercased() else { return false }
                    guard let n2 = $1.name?.uppercased() else { return true }
                    return n1 < n2
                }
                self?.tableView.reloadData()
            case .failure:
                // no op
                return
            }
        }

        if FeatureManager.shared.hasPrepopulateAttendance,
           let attendanceService = attendanceService {

            // display all attendances after receiving members and attendances
            Observable.combineLatest(OrganizationService.shared.membersObservable,
                                     attendanceService.attendancesObservable)
                .subscribe(onNext: { [weak self] members, attendances in
                    guard let self = self,
                          let attendances = attendances else {
                        return
                    }
                    self.attendances = attendances.compactMap({ (memberId: String, status: AttendanceStatus) in
                        guard let member = members.first(where: { mem in
                            mem.id == memberId
                        }) else {
                            return nil
                        }
                        return Attendance(member: member, status: status)
                    }).sorted()
                    self.tableView.reloadData()
                })
                .disposed(by: disposeBag)

            // migrate if necessary. This only gets triggered once
            Observable.combineLatest(OrganizationService.shared.membersObservable,
                                     attendanceService.needsAttendanceMigrationObservable)
                .subscribe(onNext: { [weak self] members, needsAttendances in
                    // no attendances exist for the event.
                    self?.attendanceService?.migrateAttendances(members: members)
                })
                .disposed(by: disposeBag)
        }
    }

}

// MARK: - Table view data source
extension AttendanceTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else {
            fatalError("Invalid section")
        }
        if sections[section] == .onsiteSignup {
            return 1
        } else if sections[section] == .members {
            // TODO: check feature
            return members.count
        } else if sections[section] == .attendances {
            return attendances.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count else {
            fatalError("Invalid section")
        }
        if sections[indexPath.section] == .onsiteSignup {
            let cell = tableView.dequeueReusableCell(withIdentifier: "OnSiteSignupCell", for: indexPath)
            cell.textLabel?.text = "Sign up new members"
            cell.accessoryType = .disclosureIndicator
            return cell
        } else if sections[indexPath.section] == .members {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)
            
            guard let attendanceCell = cell as? AttendanceCell else { return cell }
            // Configure the cell...
            guard indexPath.row < members.count, let event = event else { return cell }
            let member = members[indexPath.row]

            attendanceCell.configure(member: member, attended: event.attended(for: member.id), row: indexPath.row)
            return cell
        } else if sections[indexPath.section] == .attendances {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)

            guard let attendanceCell = cell as? AttendanceCell else { return cell }

            guard indexPath.row < attendances.count else {
                return cell
            }

            // Plus
            let attendance = attendances[indexPath.row]
            attendanceCell.configure(attendance: attendance, row: indexPath.row)

            return cell
        } else {
            fatalError("Invalid section")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard FeatureManager.shared.hasPrepopulateAttendance else {
            return nil
        }

        guard section < sections.count else {
            fatalError("Invalid section")
        }

        if sections[section] == .onsiteSignup {
            return "Onsite Signup"
        } else if sections[section] == .members {
            // TODO: check feature
            return "All members"
        } else if sections[section] == .attendances {
            return "Current Attendees"
        }
        return nil
    }
}

// MARK: Table view delegate
extension AttendanceTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let event = event else { return }

        if indexPath.section == 0 {
            guard let controller = UIStoryboard(name: "Events", bundle: nil)
                .instantiateViewController(identifier: "OnsiteSignupViewController") as? OnsiteSignupViewController else {
                    return
                }
            controller.practice = event
            navigationController?.pushViewController(controller, animated: true)
            LoggingService.log(type: "OnsiteSignupClicked")
            return
        }
        
        guard indexPath.row < members.count else { return }
        let member = members[indexPath.row]

        if FeatureManager.shared.hasPrepopulateAttendance {
            promptForUpdateAttendance(for: member)
        } else {
            attendanceService?.toggleAttendance(for: member)
        }
        tableView.reloadData()
    }

    // MARK: - Plus
    private func promptForUpdateAttendance(for member: FirebaseMember) {
        // show action sheet to select attendance status, then call attendanceService to update it
        let title = "Update attendance"
        let message = "Please select from the following options"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for status in AttendanceStatus.allCases {
            alert.addAction(UIAlertAction(title: status.rawValue, style: .default, handler: { (action) in
                self.attendanceService?.updateAttendance(for: member, status: status)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)
//        {
//            alert.popoverPresentationController?.sourceView = tableView
//            alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
//        }
        present(alert, animated: true, completion: nil)
    }

}
