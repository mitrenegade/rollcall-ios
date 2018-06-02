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
            let org = FirebaseOrganization(snapshot: snapshot)
            OrganizationService.shared.current.value = org
        })
    }
}
