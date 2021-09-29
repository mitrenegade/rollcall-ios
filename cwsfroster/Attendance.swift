//
//  Attendance.swift
//  rollcall
//
//  Created by Bobby Ren on 9/27/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

// new UI: includes presignup
enum AttendanceStatus: String, CaseIterable, CustomStringConvertible {
    var description: String {
        switch self {
        case .notSignedUp:
            return "None"
        case .signedUp:
            return "Confirmed"
        case .notAttending:
            return "Not attending"
        case .attended:
            return "Attended"
        case .noShow:
            return "No Show"
        }
    }

    case notSignedUp
    case signedUp
    case notAttending
    case attended
    case noShow
}

struct Attendance: Comparable {
    static func < (lhs: Attendance, rhs: Attendance) -> Bool {
        guard let lname = lhs.member.name?.lowercased() else {
            return false
        }
        guard let rname = rhs.member.name?.lowercased() else {
            return true
        }

        return lname < rname
    }

    let member: FirebaseMember
    let status: AttendanceStatus
}

// old UI: attended or not
enum AttendedStatus: Int {
    case None = 0
    case Present = 1
    case Freebie = 2
}
