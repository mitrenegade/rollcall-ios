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

    let offlineDict: [String: Any]
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
    
    func loadOrganization() -> FirebaseOrganization? {
        guard let user = AuthService.currentUser else { return nil }
        guard let organizations = offlineDict["organizations"] as? [String: Any] else { return nil }
        guard let organizationDict = organizations.filter({ (key, value) -> Bool in
            guard let dict = value as? [String: Any] else { return false }
            return dict["owner"] as? String == user.uid
        }).first else { return nil }
        guard let dict = organizationDict.value as? [String: Any] else { return nil }
        return FirebaseOrganization(id: organizationDict.key, dict: dict)
    }
    
    func eventsForOrganization() -> [FirebaseEvent]? {
        guard let organization = loadOrganization() else { return nil }
        guard let eventsDict = offlineDict["events"] as? [String: Any] else { return nil }
        let filtered = eventsDict.filter({ (key, value) -> Bool in
            guard let dict = value as? [String: Any] else { return false }
            return dict["organization"] as? String == organization.id
        })
        let mapped = filtered.flatMap({ (key, value) -> FirebaseEvent? in
            guard let dict = value as? [String: Any] else { return nil }
            return FirebaseEvent(id: key, dict: dict)
        })
        return mapped
    }
}

