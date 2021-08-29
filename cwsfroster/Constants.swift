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
import RenderPay
import RenderCloud
import FirebaseDatabase
import FirebaseAuth

let TESTING = true
let OFFLINE_MODE = false

let powerUserPromptDeferDate: String = "powerUserPromptDeferDate"

@objc class Constants: NSObject {
    static let APP_ID = "916600723"
}

let STRIPE_CLIENT_ID_DEV = "ca_ECowy0cLCEaImKunoIsUfm2n4EbhxrMO"
let STRIPE_CLIENT_ID_PROD = "ca_ECowdoBb2DfRFlBMQSZ2jT4SSXAUJ6Lx"

let FIREBASE_URL_DEV = "https://us-central1-rollcall-and-random-dev.cloudfunctions.net"
let FIREBASE_URL_PROD = "https://us-central1-rollcall-and-random-drawing.cloudfunctions.net"

let SOFT_UPGRADE_INTERVAL_DEFAULT = (3600*24*7)
let APP_STORE_URL = "itms-apps://itunes.apple.com/app/id" + Constants.APP_ID

enum NotificationType: String {
    case LogoutSuccess
    
    func name() -> Notification.Name {
        return Notification.Name(self.rawValue)
    }
}

@objc enum AttendedStatus: Int {
    case None = 0
    case Present = 1
    case Freebie = 2
}

enum MemberStatus: String {
    case inactive
    case active
}

// Firebase
var firRef = Database.database().reference()
let firAuth = Auth.auth()

enum Globals {
    static let firRef: DatabaseReference = Database.database().reference()
    static let firAuth: Auth = Auth.auth()
    static var apiService: CloudAPIService & CloudDatabaseService = RenderAPIService(baseUrl: TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD, baseRef: firRef)
    static var defaultLogger: LoggingService? = nil // TODO: use LoggingService
    static var stripeConnectService = StripeConnectService(clientId: TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD,
                                                           apiService: Globals.apiService,
                                                           logger: nil)
    static var stripePaymentService: StripePaymentService = StripePaymentService(apiService: Globals.apiService)
}

extension UIColor {
    static let bgBlue = UIColor(red: 24.0/256.0, green: 123.0/256.0, blue: 158.0/256.0, alpha: 1)
}
