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
    func attendances(for event: FirebaseEvent, completion: @escaping  (Result<[FirebaseAttendance], Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        let ref = firRef.child("attendances").queryEqual(toValue: event.id, childKey: "eventId")
        ref.observe(.value) { snapshot in
            guard snapshot.exists() else {
                completion(.failure(AttendanceError.invalidEvent))
                return
            }

            var results: [FirebaseAttendance] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for dict: DataSnapshot in allObjects {
                    let object = FirebaseAttendance(snapshot: dict)
                    results.append(object)
                }
            }
            completion(.success(results))
        }
    }

    /// Creates a new attendance for an event and member
    func createAttendance(for event: FirebaseEvent, member: FirebaseMember, status: AttendanceStatus, completion: @escaping (Result<FirebaseAttendance, Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        // old attendance format.
        // needed to support the standard tier UI
        event.addAttendance(for: member)

        // new attendance format: create an actual Attendance object
        let newRef = firRef.child("attendances").child(FirebaseAPIService.uniqueId())
        var params: [String: Any] = [
            "status": status.rawValue,
            "eventId": event.id,
            "memberId": member.id
            ]
        if let date = event.date {
            params["date"] = date
        }
        newRef.setValue(params) { error, ref in
            if let error = error {
                completion(.failure(error))
            } else {
                ref.observe(.value) { snapshot in
                    guard snapshot.exists() else {
                        completion(.failure(AttendanceError.createFailed))
                        return
                    }
                    let attendance = FirebaseAttendance(snapshot: snapshot)
                    completion(.success(attendance))
                }
            }
        }
    }

    /// Change the attending status for an existing attendance
    func updateAttendanceStatus(for attendance: FirebaseAttendance, status: AttendanceStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let memberId = attendance.memberId,
              let eventId = attendance.eventId,
              let event = EventService.shared.with(id: eventId) else {
            completion(.failure(AttendanceError.updateFailed))
            return
        }

        // old attendance format
        if status == .attended || status == .signedUp {
            event.addAttendance(for: memberId)
        } else if status == .noShow, status == .notAttending, status == .notSignedUp {
            event.removeAttendance(for: memberId)
        }

        // new attendance format
        attendance.status = status
    }
}
