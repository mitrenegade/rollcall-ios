//
//  ParseTestService.swift
//  Lunr
//
//  Created by Bobby Ren on 12/13/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAnalytics

fileprivate var singleton: LoggingService?
fileprivate var loggingRef: DatabaseReference = firRef.child("logs")

enum LoggingEvent: String {
    // first time user
    case createEmailUser
    case migrateSynchronizeParse
    case createOrganization
    case migrationFailed
    
    // upgrade
    case upgradeDisplayed
    case softUpgradeDismissed
    
    // password reset
    case passwordReset

    // settings
    case updateOrganizationName = "UpdateOrganizationName"
    case updateOrganizationLogo = "UpdateOrganizationLogo"
    case updateOrganizationEmail = "UpdateOrganizationEmail"
    case updateOrganizationPassword = "UpdateOrganizationPassword"

    // add member
    case addMembersSaved
    case addMembersCancelled

    // add member - contacts permission
    case contactsButtonClicked
    case contactsPermissionSettings
    case contactsAdded

    // subscriptions
    case subscriptionViewed
    
    case unknown
}

class LoggingService: NSObject {
    // MARK: - Singleton
    static var shared: LoggingService = LoggingService()
    
    fileprivate func writeLog(event: LoggingEvent, info: [String: Any]?) {
        let eventString: String
        switch event {
        case .unknown:
            eventString = info?["type"] as? String ?? "unknown"
        default:
            eventString = event.rawValue
        }
        
        let id = FirebaseAPIService.uniqueId()
        let ref = loggingRef.child(id)
        var params = info ?? [:]
        params["title"] = eventString
        params["timestamp"] = Date().timeIntervalSince1970
        if let userId = UserService.currentUser?.uid {
            params["userId"] = userId
        }
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] {
            params["version"] = version
        }
        if let build = Bundle.main.infoDictionary!["CFBundleVersion"] {
            params["build"] = build
        }
        ref.updateChildValues(params)
        
        // native firebase analytics
        Analytics.logEvent(eventString, parameters: info)
    }
    
    // compatible with ObjC
    class func log(type: String, message: String? = nil, info: [String: Any]? = nil, error: NSError? = nil) {
        
        var params: [String: Any]?
        if let info = info {
            params = info
        } else {
            params = [String: Any]()
        }
        params?["type"] = type
        LoggingService.log(event: .unknown, message: message, info: params, error: error)
    }
    
    class func log(event: LoggingEvent, message: String? = nil, info: [String: Any]? = nil, error: NSError? = nil) {
        #if targetEnvironment(simulator)
        if !TESTING {
            return
        }
        #endif

        var params: [String: Any]?
        if let info = info {
            params = info
        } else {
            params = [String: Any]()
        }
        
        if let error = error {
            params?["errorCode"] = error.code
            params?["error"] = error.localizedDescription
        }
        if let message = message {
            params?["message"] = message
        }
        
        LoggingService.shared.writeLog(event: event, info: params)
    }
}
