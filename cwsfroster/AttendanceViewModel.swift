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
    func updateAttendance(for member: FirebaseMember, event: FirebaseEvent, status: AttendanceStatus) {
        AttendanceService.shared.createOrUpdateAttendance(for: event, member: member, status: status) { result in
            // no op
        }
    }
}
