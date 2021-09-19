//
//  AttendanceCellViewModel.swift
//  rollcall
//
//  Created by Bobby Ren on 9/18/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

internal struct AttendanceViewModel {

    // MARK: Standard
    func attendedStatusImage(for member: FirebaseMember, event: FirebaseEvent) -> UIImage? {
        if event.attended(for: member.id) != AttendedStatus.None {
            return UIImage(named: "checked")
        } else {
            return UIImage(named: "unchecked")
        }
    }

    func toggleAttendance(for member: FirebaseMember, event: FirebaseEvent) {
        print("BOBBYTEST toggle \(member.id) event \(event.id) present? \(event.attended(for: member.id) == .Present)")
        if event.attended(for: member.id) == .Present {
            // old attendance format. Updates events/id/attendees
            event.removeAttendance(for: member.id)

            // new attendances format
            AttendanceService.shared.createOrUpdateAttendance(for: event, member: member, status: .notSignedUp) { result in
                // no op
            }
        } else {
            // old attendance format. Updates events/id/attendees
            event.addAttendance(for: member.id)

            // new attendances format
            AttendanceService.shared.createOrUpdateAttendance(for: event, member: member, status: .attended) { result in
                // no op
            }
        }
    }

    // MARK: Plus
    func attendanceStatusText(for status: AttendanceStatus) -> String {
        status.rawValue
    }

    func updateAttendance(for member: FirebaseMember, event: FirebaseEvent, status: AttendanceStatus) {
        AttendanceService.shared.createOrUpdateAttendance(for: event, member: member, status: status) { result in
            // no op
        }
    }

    // MARK: -
    /// Migrate to AttendanceStatus for users who have switched to Plus.
    func migrateAttendances(event: FirebaseEvent, members: [FirebaseMember], attendances: [String: AttendanceStatus]) {
        let membersAttending: [FirebaseMember] = members.filter { member in
            event.attended(for: member.id) == .Present
        }
        let missingMembers: [FirebaseMember] = membersAttending.compactMap { member in
            if attendances[member.id] != nil {
                return nil
            }
            return member
        }
        print("BOBBYTEST \(missingMembers)")
        let group = DispatchGroup()
        for member in missingMembers {
            group.enter()
            AttendanceService.shared.createOrUpdateAttendance(for: event, member: member, status: .signedUp) { _ in
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            let params: [String: Any] = ["event": event.id, "members": missingMembers.map { $0.id }]
            LoggingService.log(event: .attendancesMigrated, message: nil, info: params, error: nil)
        }
    }
}
