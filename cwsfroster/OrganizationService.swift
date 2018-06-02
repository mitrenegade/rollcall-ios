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
    
    fileprivate var disposeBag: DisposeBag
    let current: Variable<FirebaseOrganization?> = Variable(nil)
    
    override init() {
        disposeBag = DisposeBag()
    }
}
