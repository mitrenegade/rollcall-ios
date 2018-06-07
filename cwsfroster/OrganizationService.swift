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
    
    func events(for org: FirebaseOrganization, completion: (([FirebaseEvent]?, Error?) -> Void)?) {
        let ref = firRef.child("organizations").child(org.id)
        ref.queryOrdered(byChild: "organization").queryEqual(toValue: org.id).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion?(nil, nil)
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
}
