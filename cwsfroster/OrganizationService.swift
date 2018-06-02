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
    
    func startObservingOrganization() {
        disposeBag = DisposeBag() // clear previous listeners
        
        guard let userId = firAuth.currentUser?.uid else { return }
        firRef.child("organizations").queryOrdered(byChild: "owner").queryEqual(toValue: userId).observe(.value, with: { [weak self] (snapshot) in
            guard snapshot.exists() else {
                self?.current.value = nil
                return
            }
            if let data =  snapshot.children.allObjects.first as? DataSnapshot {
                let org = FirebaseOrganization(snapshot: data)
                OrganizationService.shared.current.value = org
            }
        })
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
}
