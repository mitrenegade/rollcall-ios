//
//  AuthService.swift
//  rollcall
//
//  Created by Bobby Ren on 5/20/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class AuthService: NSObject {
    class func logout() {
        try! firAuth.signOut()
        
        OrganizationService.shared.onLogout()
    }
    
    // TODO: use loginState
    class var isLoggedIn: Bool {
        return firAuth.currentUser != nil
    }
    
    class var currentUser: User? {
        return firAuth.currentUser
    }
}
