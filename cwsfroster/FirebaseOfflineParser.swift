//
//  FirebaseOfflineParser.swift
//  rollcall
//
//  Created by Bobby Ren on 6/9/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

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
    
    func offlineOrganization() -> FirebaseOrganization? {
        guard UserService.shared.isLoggedIn else { return nil }
        guard let organizations = offlineDict["organizations"] as? [String: Any] else { return nil }
        guard let organizationDict = organizations.filter({ (key, value) -> Bool in
            guard let dict = value as? [String: Any] else { return false }
            return dict["owner"] as? String == UserService.shared.currentUserID
        }).first else { return nil }
        guard let dict = organizationDict.value as? [String: Any] else { return nil }
        return FirebaseOrganization(id: organizationDict.key, dict: dict)
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
            return FirebaseEvent(id: key, dict: dict)
        })
        return mapped
    }
    
    fileprivate func allMembers() -> [FirebaseMember] {
        guard let membersDict = offlineDict["members"] as? [String: Any] else { return [] }
        return membersDict.compactMap({ (key, val) -> FirebaseMember? in
            guard let dict = val as? [String: Any] else { return nil }
            return FirebaseMember(id: key, dict: dict)
        })
    }
    
    func offlineMembers() -> [FirebaseMember] {
        guard let organization = offlineOrganization() else { return [] }
        guard let organizationMembers = offlineDict["organizationMembers"] as? [String: Any], let membersDict = organizationMembers[organization.id] as? [String: Any] else { return [] }
        return allMembers().filter({ (member) -> Bool in
            return membersDict[member.id] as? String == "active"
        })
    }
    
    func offlineAttendances(for event: FirebaseEvent) -> [String] {
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
    
}

