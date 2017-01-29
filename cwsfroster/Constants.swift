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
