//
//  IntroViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse

// MARK: Swift notifications
extension IntroViewController {
    func notifyForLogInSuccess() {
        self.notify(.LoginSuccess, object: nil, userInfo: nil)
    }
    
    @IBAction func didClickLogin(_ sender: AnyObject?) {
        if OFFLINE_MODE {
            self.offlineLogin()
        }
        else {
            self.login()
        }
    }
    
    func offlineLogin() {
        PFUser.enableAutomaticUser()
        self.goToPractices()
    }
}
