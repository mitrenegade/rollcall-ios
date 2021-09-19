//
//  AttendanceService.swift
//  rollcall
//
//  Created by Bobby Ren on 9/11/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Firebase
import RxSwift

class AttendanceService: NSObject {
    static let shared: AttendanceService = AttendanceService()

    enum AttendanceError: Error {
        case invalidEvent
        case createFailed
        case updateFailed
    }

    /// Fetches attendances for an event from Firebase.
    /// No caching now to ensure accuracy
    func attendances(for event: FirebaseEvent, completion: @escaping  (Result<[String: AttendanceStatus], Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        let ref = firRef.child("events").child(event.id).child("attendances")
        ref.observe(.value) { snapshot in
            guard snapshot.exists() else {
                completion(.failure(AttendanceError.invalidEvent))
                return
            }

            var results: [String: AttendanceStatus] = [:]
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for object in allObjects {
                    results[object.key] = AttendanceStatus(rawValue: object.value as! String)
                }
            }
            completion(.success(results))
        }
    }

    /// Creates a new attendance for an event and member
    func createOrUpdateAttendance(for event: FirebaseEvent, member: FirebaseMember, status: AttendanceStatus, completion: @escaping (Result<FirebaseAttendance, Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        // new attendance format. Updates events/id/attendances
        let eventRef = firRef.child("events").child(event.id).child("attendances").child(member.id)
        eventRef.setValue(status.rawValue)

        // also updates memberEvents/id
        let memberEventsRef = firRef.child("memberEvents")
            .child(member.id)
            .child(event.id)
        memberEventsRef.setValue(status.rawValue)
    }

}
