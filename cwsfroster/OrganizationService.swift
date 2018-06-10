//
//  OrganizationService.swift
//  rollcall
//
//  Created by Ren, Bobby on 6/1/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase
import RxOptional
import RxSwift

class OrganizationService: NSObject {
    static let shared = OrganizationService()
    
    fileprivate var disposeBag: DisposeBag!
    let current: Variable<FirebaseOrganization?> = Variable(nil)
    
    var organizerRef: DatabaseReference?
    var organizerRefHandle: UInt?
    func startObservingOrganization() {
        guard !OFFLINE_MODE else {
            let org = FirebaseOfflineParser.shared.offlineOrganization()
            current.value = org
            return
        }
        print("Start observing organization")
        disposeBag = DisposeBag() // clear previous listeners
        
        guard let userId = firAuth.currentUser?.uid else { return }
        let ref = firRef.child("organizations")
        organizerRefHandle = ref.queryOrdered(byChild: "owner").queryEqual(toValue: userId).observe(.value, with: { [weak self] (snapshot) in
            guard snapshot.exists() else {
                self?.current.value = nil
                return
            }
            if let data =  snapshot.children.allObjects.first as? DataSnapshot {
                let org = FirebaseOrganization(snapshot: data)
                OrganizationService.shared.current.value = org
            }
        })
        organizerRef = ref
    }
    
    func onLogout() {
        // stop observing organizer ref
        if let handle = organizerRefHandle {
            print("Start observing organization ended")
            organizerRef?.removeObserver(withHandle: handle)
        }
        organizerRef = nil
        organizerRefHandle = nil
        current.value = nil
    }
    
    func createOrUpdateOrganization(orgId: String, ownerId: String, name: String?, leftPowerUserFeedback: Bool, migrated: Bool = false) {
        let ref = firRef.child("organizations").child(orgId)
        var params: [String: Any] = ["owner": ownerId]
        params["leftPowerUserFeedback"] = leftPowerUserFeedback
        if let name = name {
            params["name"] = name
        }
        if migrated {
            params["migratedFromParse"] = true
        }
        ref.updateChildValues(params)
    }
    
    func events(completion: (([FirebaseEvent], Error?) -> Void)?) {
        guard let org = current.value else {
            completion?([], NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }
        
        guard !OFFLINE_MODE else {
            let events = FirebaseOfflineParser.shared.offlineEvents()
            completion?(events, nil)
            return
        }
        
        let ref = firRef.child("events")
        ref.queryOrdered(byChild: "organization").queryEqual(toValue: org.id).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion?([], nil)
                return
            }

            var results: [FirebaseEvent] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for eventDict: DataSnapshot in allObjects {
                    let event = FirebaseEvent(snapshot: eventDict)
                    results.append(event)
                }
            }
            completion?(results, nil)
        })
    }
    
    func members(completion: (([FirebaseMember], Error?) -> Void)?) {
        guard let org = current.value else {
            completion?([], NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }

        guard !OFFLINE_MODE else {
            let members = FirebaseOfflineParser.shared.offlineMembers()
            completion?(members, nil)
            return
        }
        
        let ref = firRef.child("members")
        ref.queryOrdered(byChild: "organization").queryEqual(toValue: org.id).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion?([], nil)
                return
            }
            
            var results: [FirebaseMember] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for eventDict: DataSnapshot in allObjects {
                    let event = FirebaseMember(snapshot: eventDict)
                    results.append(event)
                }
            }
            completion?(results, nil)
        })
    }
    
    func createMember(email: String, name: String? = nil, notes: String? = nil, status: MemberStatus, completion:@escaping (FirebaseMember?, NSError?) -> Void) {
        guard let org = current.value else {
            completion(nil, NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }

        print ("Create member")
        
        let ref = firRef.child("members").child(FirebaseAPIService.uniqueId())
        var params: [String: Any] = ["email": email, "name": name, "notes": notes, "createdAt": Date().timeIntervalSince1970, "organization": org.id]
        switch status {
        case .Inactive:
            params["status"] = "inactive"
        case .Active:
            params["status"] = "active"
        default:
            params["status"] = "unknown"
        }
        ref.setValue(params) { (error, ref) in
            if let error = error as NSError? {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion(nil, nil)
                        return
                    }
                    let member = FirebaseMember(snapshot: snapshot)

                    // set organizationMembers
                    let orgRef = firRef.child("organizationMembers").child(org.id)
                    orgRef.updateChildValues([member.id: true])
                    
                    completion(member, nil)
                })
            }
        }
    }
    
    func deleteMember(_ member: FirebaseMember, completion: ((Bool, Error?) -> Void)?) {
        guard let org = current.value else {
            completion?(false, NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }
        
        let memberRef = firRef.child("members")
        memberRef.setValue(nil, forKey: member.id)
        
        let orgRef = firRef.child("organizationMembers").child(org.id)
        orgRef.setValue(nil, forKey: member.id)
        
        completion?(true, nil)
    }
}
