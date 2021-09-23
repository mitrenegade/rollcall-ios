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
import RxCocoa

class OrganizationService {
    static let shared = OrganizationService()

    private var organizationDisposeBag = DisposeBag()

    private let organizationRelay: BehaviorRelay<FirebaseOrganization?> = BehaviorRelay(value: nil)
    var organizationObservable: Observable<FirebaseOrganization?> {
        organizationRelay.distinctUntilChanged()
    }
    var current: FirebaseOrganization? {
        organizationRelay.value
    }

    private let loadingRelay: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    var loadingObservable: Observable<Bool> {
        loadingRelay.distinctUntilChanged()
    }

    var organizerRef: DatabaseReference?
    var organizerRefHandle: UInt?
    
    var currentOrganizationName: String? {
        organizationRelay.value?.name
    }

    var currentOrganizationId: String? {
        organizationRelay.value?.id
    }

    private let membersRelay: BehaviorRelay<[FirebaseMember]> = BehaviorRelay(value: [])
    var membersObservable: Observable<[FirebaseMember]> {
        membersRelay
            .distinctUntilChanged()
    }

    var memberRef: DatabaseReference?
    var memberRefHandle: UInt?

    // MARK: -

    func onLogout() {
        stopObservingOrganization()
        stopObservingMembers()
    }

    // MARK: - Rx for Organizations

    func startObservingOrganization(for userId: String) {
        print("\(self) - startObservingOrganization userID \(userId)")
        loadingRelay.accept(true)
        guard !OFFLINE_MODE else {
            let org = FirebaseOfflineParser.shared.offlineOrganization()
            organizationRelay.accept(org)
            loadingRelay.accept(false)
            return
        }

        let ref = firRef.child("organizations")
        organizerRefHandle = ref.queryOrdered(byChild: "owner").queryEqual(toValue: userId).observe(.value, with: { [weak self] (snapshot) in
            self?.loadingRelay.accept(false)
            guard snapshot.exists() else {
                if let orgName = UserService.shared.currentUserEmail {
                    self?.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
                } else {
                    UserService.shared.logout()
                    self?.loadingRelay.accept(false)
                }
                return
            }
            if let data =  snapshot.children.allObjects.first as? DataSnapshot {
                let org = FirebaseOrganization(snapshot: data)
                self?.organizationRelay.accept(org)
            }
        })
        organizerRef = ref

        // Start observing mebers for any orgnanization
        organizationObservable
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] organization in
                self?.startObservingMembers(for: organization)
            })
            .disposed(by: organizationDisposeBag)

    }
    
    func stopObservingOrganization() {
        print("\(self) - stopObservingOrganization")

        // stop observing organizer ref
        if let handle = organizerRefHandle {
            organizerRef?.removeObserver(withHandle: handle)
        }
        organizerRef = nil
        organizerRefHandle = nil
        organizationRelay.accept(nil)

        organizationDisposeBag = DisposeBag()
    }

    func createOrUpdateOrganization(orgId: String, ownerId: String, name: String?, leftPowerUserFeedback: Bool) {
        let ref = firRef.child("organizations").child(orgId)
        var params: [String: Any] = ["owner": ownerId]
        params["leftPowerUserFeedback"] = leftPowerUserFeedback
        if let name = name {
            params["name"] = name
        }
        ref.updateChildValues(params)
    }

    // MARK: - Organization updaters
    func updateName(_ name: String) {
        organizationRelay.value?.name = name
    }

    func updatePhoto(_ urlString: String) {
        organizationRelay.value?.photoUrl = urlString
    }

    func events(completion: (([FirebaseEvent], Error?) -> Void)?) {
        guard let org = organizationRelay.value else {
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

    /// Returns the current members
    func members(completion: ((Result<[FirebaseMember], Error>) -> Void)?) {
        guard let org = organizationRelay.value else {
            completion?(.failure(NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"])))
            return
        }

        guard !OFFLINE_MODE else {
            completion?(.success( FirebaseOfflineParser.shared.offlineMembers()))
            return
        }

        completion?(.success(membersRelay.value))
    }
//        
//        let ref = firRef.child("members")
//        ref.queryOrdered(byChild: "organization").queryEqual(toValue: org.id).observeSingleEvent(of: .value, with: { snapshot in
//            guard snapshot.exists() else {
//                completion?([], nil)
//                return
//            }
//            
//            var results: [FirebaseMember] = []
//            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
//                for eventDict: DataSnapshot in allObjects {
//                    let event = FirebaseMember(snapshot: eventDict)
//                    results.append(event)
//                }
//            }
//            completion?(results, nil)
//        })
//    }

    // MARK: - Rx for members

    // Start observing members when a new organization is found.
    private func startObservingMembers(for organization: FirebaseOrganization) {
        guard !OFFLINE_MODE else {
            let members = FirebaseOfflineParser.shared.offlineMembers()
            membersRelay.accept(members)
            return
        }

        let ref = firRef.child("members")
        memberRefHandle = ref.queryOrdered(byChild: "organization")
            .queryEqual(toValue: organization.id)
            .observe(.value) { [weak self] snapshot in
                guard snapshot.exists() else {
                    self?.membersRelay.accept([])
                    return
                }

                let results = (snapshot.children.allObjects as? [DataSnapshot])?
                    .compactMap { eventDict in
                        FirebaseMember(snapshot: eventDict)
                    } ?? []

                self?.membersRelay.accept(results)
            }
        memberRef = ref
    }

    private func stopObservingMembers() {
        print("\(self) - stopObservingMembers")

        // stop observing organizer ref
        if let handle = memberRefHandle {
            memberRef?.removeObserver(withHandle: handle)
        }
        memberRef = nil
        memberRefHandle = nil
        membersRelay.accept([])
    }
    
    func createMember(email: String? = nil, name: String? = nil, notes: String? = nil, status: MemberStatus, completion:@escaping (FirebaseMember?, NSError?) -> Void) {
        guard let org = organizationRelay.value else {
            completion(nil, NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }

        print ("Create member")
        
        let ref = firRef.child("members").child(FirebaseAPIService.uniqueId())
        var params: [String: Any] = ["createdAt": Date().timeIntervalSince1970, "organization": org.id]
        if let email = email {
            params["email"] = email
        }
        if let name = name {
            params["name"] = name
        }
        if let notes = notes {
            params["notes"] = notes
        }
        params["status"] = status.rawValue
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
        guard let org = organizationRelay.value else {
            completion?(false, NSError(domain: "renderapps", code: 0, userInfo: ["reason": "no org"]))
            return
        }
        
        let memberRef = firRef.child("members").child(member.id)
        memberRef.removeValue()
        
        let orgRef = firRef.child("organizationMembers").child(org.id).child(member.id)
        orgRef.removeValue()
        
        completion?(true, nil)
    }
}
