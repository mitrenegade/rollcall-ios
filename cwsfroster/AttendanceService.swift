//
//  AttendanceService.swift
//  rollcall
//
//  Created by Bobby Ren on 9/11/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Firebase
import RxSwift
import RxCocoa

enum AttendanceError: Error {
    case notAuthenticated
    case invalidEvent
    case createFailed
    case updateFailed
}

class AttendanceService: NSObject {

    // MARK: - Properties

    private let event: FirebaseEvent

    // attendances for a given event
    private let attendancesRelay = BehaviorRelay<[String: AttendanceStatus]?>(value: nil)
    var attendancesObservable: Observable<[String: AttendanceStatus]?> {
        attendancesRelay
            .distinctUntilChanged()
    }

    private let needsAttendanceMigrationRelay = BehaviorRelay<Bool>(value: false)
    // This observable event occurs once if we cannot find the attendances endpoint for an event
    var needsAttendanceMigrationObservable: Observable<Bool> {
        needsAttendanceMigrationRelay
            .filter { $0 }
            .take(1)
    }

    // MARK: -

    var attendancesRefHandle: UInt?
    var attendancesRef: DatabaseReference?

    let disposeBag = DisposeBag()

    // MARK: - Initialization

    init(event: FirebaseEvent) {
        self.event = event

        super.init()
        setupBindings()
    }

    deinit {
        stopObservingAttendances()
    }

    private func setupBindings() {
        guard UserService.shared.isLoggedIn else { return }

        startObservingAttendances()
    }

    private func startObservingAttendances() {
        guard !OFFLINE_MODE else {
            FirebaseOfflineParser.shared.offlineAttendanceStatusDriver()
                .drive(attendancesRelay)
                .disposed(by: disposeBag)
            return
        }

        print("BOBBYTEST startObservingAttendances \(self) for event \(event.id)")
        let ref = firRef.child("events").child(event.id).child("attendances")
        attendancesRefHandle = ref.observe(.value) { [weak self] snapshot in
            guard snapshot.exists() else {
                print("BOBBYTEST needsAttendanceMigration for event \(self?.event.id ?? "")")
                self?.attendancesRelay.accept(nil)
                self?.needsAttendanceMigrationRelay.accept(true)
                return
            }

            var results: [String: AttendanceStatus] = [:]
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for object in allObjects {
                    results[object.key] = AttendanceStatus(rawValue: object.value as! String)
                }
            }
            print("BOBBYTEST event attendance \(results.count)")
            self?.attendancesRelay.accept(results)
        }
        attendancesRef = ref
    }

    private func stopObservingAttendances() {
        if let handle = attendancesRefHandle {
            attendancesRef?.removeObserver(withHandle: handle)
        }
        attendancesRef = nil
        attendancesRefHandle = nil
        attendancesRelay.accept(nil)
    }

    /// Creates a new attendance for an event and member
    func createOrUpdateAttendance(for member: FirebaseMember, status: AttendanceStatus, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !OFFLINE_MODE else {
            FirebaseOfflineParser.shared.offlineUpdateAttendanceStatus(member: member, status: status)
            completion(.success(()))
            return
        }

        guard UserService.shared.isLoggedIn else {
            completion(.failure(AttendanceError.notAuthenticated))
            return
        }

        // new attendance format. Updates events/id/attendances
        let eventRef = firRef.child("events").child(event.id).child("attendances").child(member.id)
        eventRef.setValue(status.rawValue)

        // also updates memberEvents/id
        let memberEventsRef = firRef.child("memberEvents")
            .child(member.id)
            .child(event.id)
        memberEventsRef.setValue(status.rawValue)

        completion(.success(()))
    }

    /// Change attendance status for a member
    func toggleAttendance(for member: FirebaseMember) {
        print("BOBBYTEST toggle \(member.id) event \(event.id) present? \(event.attended(for: member.id) == .Present)")
        if event.attended(for: member.id) == .Present {
            // old attendance format. Updates events/id/attendees
            event.removeAttendance(for: member.id)

            // new attendances format
            createOrUpdateAttendance(for: member, status: .notSignedUp) { result in
                // no op
            }
        } else {
            // old attendance format. Updates events/id/attendees
            event.addAttendance(for: member.id)

            // new attendances format
            createOrUpdateAttendance(for: member, status: .attended) { result in
                // no op
            }
        }
    }

    // MARK: Plus
    func updateAttendance(for member: FirebaseMember, status: AttendanceStatus) {
        createOrUpdateAttendance(for: member, status: status) { result in
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
            createOrUpdateAttendance(for: member, status: .signedUp) { _ in
                group.leave()
            }
        }
        group.notify(queue: DispatchQueue.main) { [weak self] in
            if membersAttending.isNotEmpty {
                let params: [String: Any] = ["event": self?.event.id, "members": membersAttending.map { $0.id }]
                LoggingService.log(event: .attendancesMigrated, message: nil, info: params, error: nil)
            }
        }
    }
}
