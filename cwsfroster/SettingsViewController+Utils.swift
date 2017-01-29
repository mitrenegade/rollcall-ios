//
//  SettingsViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension SettingsViewController {
    
    func notifyForLogoutInSuccess() {
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
    }
}
