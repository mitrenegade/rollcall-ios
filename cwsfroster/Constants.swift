//
//  Constants.swift
//  Rollcall
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation
import Firebase

let TESTING = false
let OFFLINE_MODE = false

let powerUserPromptDeferDate: String = "powerUserPromptDeferDate"

@objc class Constants: NSObject {
    static let APP_ID = "916600723"
}

let SOFT_UPGRADE_INTERVAL_DEFAULT = (3600*24*7)
let APP_STORE_URL = "itms-apps://itunes.apple.com/app/id" + Constants.APP_ID

enum NotificationType: String {
    case LogoutSuccess
    case LoginSuccess
    
    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

@objc enum AttendedStatus: Int {
    case None = 0
    case Present = 1
    case Freebie = 2
}

@objc enum MemberStatus: Int {
    case Inactive = 0
    case Beginner = 1 // DEPRECATED
    case Active = 2
}

// Firebase
var firRef = Database.database().reference()
let firAuth = Auth.auth()

