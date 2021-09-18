//
//  AttendanceCellViewModel.swift
//  rollcall
//
//  Created by Bobby Ren on 9/18/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

internal struct AttendanceCellViewModel {
    let event: FirebaseEvent
    let member: FirebaseMember

    // Old UI
    var attendedStatusImage: UIImage {
        if event.attended(for: member.id) != AttendedStatus.None {
            return UIImage(named: "checked")!
        } else {
            return UIImage(named: "unchecked")!
        }
    }
}
