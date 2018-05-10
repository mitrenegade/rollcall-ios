//
//  Constants.swift
//  Rollcall
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation

let TEST = false // test options
let TESTING = true // dev/prod server
let OFFLINE_MODE = false
let PARSE_APP_ID = "1rpbRs78obshXacjudYUWffbxIiXs05cti4AQ9XY"
let PARSE_CLIENT_KEY = "Saw8mERqjgFuswlvBgHjCCfK7SR8aKuU9Vg7uyMA"
let PARSE_SERVER = "https://rollcall-server.herokuapp.com/parse"

let powerUserPromptDeferDate: String = "powerUserPromptDeferDate"

@objc class Constants: NSObject {
    static let APP_ID = "916600723"
}

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

