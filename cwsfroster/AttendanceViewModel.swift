//
//  AttendanceCellViewModel.swift
//  rollcall
//
//  Created by Bobby Ren on 9/18/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

internal struct AttendanceViewModel {

    private let attendanceService: AttendanceService

    private let event: FirebaseEvent

    // Creates an AttendanceViewModel for a given event.
    // This also creates an AttendanceService
    init(event: FirebaseEvent) {
        self.event = event
        attendanceService = AttendanceService(event: event)
    }

    // MARK: Standard
    func attendedStatusImage(for member: FirebaseMember) -> UIImage? {
        if event.attended(for: member.id) != AttendedStatus.None {
            return UIImage(named: "checked")
        } else {
            return UIImage(named: "unchecked")
        }
    }

    func toggleAttendance(for member: FirebaseMember) {
        print("BOBBYTEST toggle \(member.id) event \(event.id) present? \(event.attended(for: member.id) == .Present)")
        if event.attended(for: member.id) == .Present {
            // old attendance format. Updates events/id/attendees
            event.removeAttendance(for: member.id)

            // new attendances format
            attendanceService.createOrUpdateAttendance(for: member, status: .notSignedUp) { result in
                // no op
            }
        } else {
            // old attendance format. Updates events/id/attendees
            event.addAttendance(for: member.id)

            // new attendances format
            attendanceService.createOrUpdateAttendance(for: member, status: .attended) { result in
                // no op
            }
        }
    }

    // MARK: Plus
    func updateAttendance(for member: FirebaseMember, status: AttendanceStatus) {
        attendanceService.createOrUpdateAttendance(for: member, status: status) { result in
            // no op
        }
    }

    // MARK: -
    /// Migrate to AttendanceStatus for users who have switched to Plus.
    func migrateAttendances(members: [FirebaseMember]) {
        let membersAttending: [FirebaseMember] = members.filter { member in
            event.attended(for: member.id) == .Present
        }
        let group = DispatchGroup()
        for member in membersAttending {
            group.enter()
            attendanceService.createOrUpdateAttendance(for: member, status: .signedUp) { _ in
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) {
            if membersAttending.isNotEmpty {
                let params: [String: Any] = ["event": event.id, "members": membersAttending.map { $0.id }]
                LoggingService.log(event: .attendancesMigrated, message: nil, info: params, error: nil)
            }
        }
    }
}
