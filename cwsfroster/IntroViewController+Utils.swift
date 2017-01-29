//
//  IntroViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

// MARK: Swift notifications
extension IntroViewController {
    func notifyForLoggedInSuccess() {
        self.notify(.LoginSuccess, object: nil, userInfo: nil)
    }
}
