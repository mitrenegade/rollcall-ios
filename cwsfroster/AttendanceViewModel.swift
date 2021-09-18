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
            event.removeAttendance(for: member)
        } else {
            event.addAttendance(for: member)
        }
    }

    // MARK: Plus
}
