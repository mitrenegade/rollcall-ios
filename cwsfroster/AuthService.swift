//
//  AuthService.swift
//  rollcall
//
//  Created by Bobby Ren on 5/20/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import Firebase

class AuthService: NSObject {
    class func logout() {
        try! firAuth.signOut()
        PFUser.logOut()
        Organization.reset()
        
        OrganizationService.shared.onLogout()
    }
    
    // TODO: use loginState
    class var isLoggedIn: Bool {
        return PFUser.current() != nil || firAuth.currentUser != nil
    }
}
