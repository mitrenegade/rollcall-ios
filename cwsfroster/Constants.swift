//
//  Constants.swift
//  Rollcall
//
//  Created by Bobby Ren on 5/8/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Foundation

let TEST = false

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
    case Beginner = 1 // member can be a beginner and all their attendances will be marked as freebie.
    case Active = 2
}

