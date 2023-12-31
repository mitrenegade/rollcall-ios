//
//  FirebaseOfflineParser.swift
//  rollcall
//
//  Created by Bobby Ren on 6/9/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import RxSwift
import RxCocoa
import UIKit

class FirebaseOfflineParser: NSObject {
    static let shared = FirebaseOfflineParser()

    fileprivate let offlineDict: [String: Any]
    override init() {
        let filePath = Bundle.main.path(forResource: "rollcall-and-random-dev-export", ofType: "json")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath!), options: [])
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            print("json: \(json)")
            offlineDict = json as! [String: Any]
        } catch let error {
            print("error \(error)")
            offlineDict = [:]
        }
        super.init()
    }

    func offlineUser() -> FirebaseUser? {
        guard UserService.shared.isLoggedIn else { return nil }
        guard let users = offlineDict["users"] as? [String: Any] else { return nil }
        guard let dict = users.first else { return nil }
        return FirebaseUser(key: dict.key, dict: dict.value as? [String : Any])
    }
    
    func offlineOrganization() -> FirebaseOrganization? {
        guard UserService.shared.isLoggedIn else { return nil }
        guard let organizations = offlineDict["organizations"] as? [String: Any] else { return nil }
        guard let organizationDict = organizations.filter({ (key, value) -> Bool in
            guard let dict = value as? [String: Any] else { return false }
            return dict["owner"] as? String == UserService.shared.currentUserID
        }).first else { return nil }
        guard let dict = organizationDict.value as? [String: Any] else { return nil }
        return FirebaseOrganization(key: organizationDict.key, dict: dict)
    }
    
    func offlineEvents() -> [FirebaseEvent] {
        guard let organization = offlineOrganization() else { return [] }
        guard let eventsDict = offlineDict["events"] as? [String: Any] else { return [] }
        let filtered = eventsDict.filter({ (key, value) -> Bool in
            guard let dict = value as? [String: Any] else { return false }
            return dict["organization"] as? String == organization.id
        })
        let mapped = filtered.compactMap({ (key, value) -> FirebaseEvent? in
            guard let dict = value as? [String: Any] else { return nil }
            return FirebaseEvent(key: key, dict: dict)
        })
        return mapped
    }
    
    fileprivate func allMembers() -> [FirebaseMember] {
        guard let membersDict = offlineDict["members"] as? [String: Any] else { return [] }
        return membersDict.compactMap({ (key, val) -> FirebaseMember? in
            guard let dict = val as? [String: Any] else { return nil }
            return FirebaseMember(key: key, dict: dict)
        })
    }
    
    func offlineMembers() -> [FirebaseMember] {
        guard let organization = offlineOrganization() else { return [] }
        guard let organizationMembers = offlineDict["organizationMembers"] as? [String: Any], let membersDict = organizationMembers[organization.id] as? [String: Any] else { return [] }
        return allMembers().filter({ (member) -> Bool in
            return membersDict[member.id] as? String == "active"
        })
    }
    
    func offlineAttendedStatuses(for event: FirebaseEvent) -> [String] {
        guard let eventsDict = offlineDict["events"] as? [String: Any] else { return [] }
        guard let eventDict = eventsDict[event.id] as? [String: Any] else { return [] }
        guard let attendees = eventDict["attendees"] as? [String: Bool] else { return [] }
        return attendees.compactMap({ (key, val) -> String? in
            if val == true {
                return key
            } else {
                return nil
            }
        })
    }

    /// A `BehaviorRelay` of attendanceStatuses for member IDs.
    /// This BehaviorRelay uses the same data for all event IDs, and provides a way
    /// to observe changes in attendance after updating the attendance string.
    /// It does not need to match the event's members' offline attended status.
    var attendanceStatusRelay = BehaviorRelay<[String: AttendanceStatus]>(value: [:])

    /// Returns an observable attendance status
    func offlineAttendanceStatusObservable() -> Observable<[String: AttendanceStatus]> {
        return attendanceStatusRelay.asObservable()
    }

    /// Returns a driver for attendance status
    func offlineAttendanceStatusDriver() -> Driver<[String: AttendanceStatus]> {
        return attendanceStatusRelay.asDriver()
    }

    /// update offline attendance status during offline mode
    func offlineUpdateAttendanceStatus(member: FirebaseMember, status: AttendanceStatus) {
        var eventAttendance = attendanceStatusRelay.value
        eventAttendance[member.id] = status
        attendanceStatusRelay.accept(eventAttendance)
    }
}

