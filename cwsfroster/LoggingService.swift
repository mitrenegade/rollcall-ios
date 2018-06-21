//
//  ParseTestService.swift
//  Lunr
//
//  Created by Bobby Ren on 12/13/16.
//  Copyright © 2016 RenderApps. All rights reserved.
//

import UIKit
import Parse

enum TestAlertType: String {
    case GenericTestAlert
}

import UIKit
import Firebase

fileprivate var singleton: LoggingService?
fileprivate var loggingRef: DatabaseReference = firRef.child("logs")

enum LoggingEvent: String {
    // first time user
    case createEmailUser
    case migrateSynchronizeParse
    case createOrganization
    
    // upgrade
    case upgradeDisplayed
    case softUpgradeDismissed

    case unknown
}

class LoggingService: NSObject {
    // MARK: - Singleton
    static var shared: LoggingService = LoggingService()
    
    fileprivate func writeLog(event: LoggingEvent, info: [String: Any]?) {
        let eventString: String
        switch event {
        case .unknown:
            eventString = info?["title"] as? String ?? "unknown"
        default:
            eventString = event.rawValue
        }
        
        let id = FirebaseAPIService.uniqueId()
        let ref = loggingRef.child(eventString).child(id)
        var params = info ?? [:]
        params["timestamp"] = Date().timeIntervalSince1970
        if let userId = AuthService.currentUser?.uid {
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
    
    func log(event: LoggingEvent, message: String? = nil, info: [String: Any]?, error: NSError? = nil) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        if !TESTING {
            return
        }
        #endif
        var params: [String: Any] = info ?? [:]
        if let message = message {
            params["message"] = message
        }
        if let error = error {
            params["error"] = "\(error)"
        }
        writeLog(event: event, info: params)
    }
}

class ParseLog: NSObject {
    class func log(type: TestAlertType, title: String?, message: String?, params: NSDictionary?, error: NSError?) {
        log(typeString: type.rawValue, title: title, message: message, params: params, error: error)
    }

    // compatible with ObjC
    class func log(typeString: String, title: String?, message: String?, params: NSDictionary?, error: NSError?) {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
        if !TESTING {
            return
        }
        #endif

        var info: [String: Any]?
        if let params = params as? [String: Any], let error = error {
            info = params
            info?["error"] = error
        } else if let params = params as? [String: Any] {
            info = params
        } else if let error = error {
            info = ["error": error]
        } else {
            info = [String: Any]()
        }
        info?["title"] = typeString
        LoggingService.shared.log(event: .unknown, message: message, info: info, error: error)
    }
}

extension UIViewController {

    func testAlert(_ title: String, message: String?, type: TestAlertType, error: Error? = nil, params: [String: Any]? = nil, completion: (() -> Void)? = nil) {
        
        var paramsDict: NSDictionary? = nil
        if let params = params {
            paramsDict = NSDictionary(dictionary: params)
        }
        let err: NSError? = error as? NSError
        
        ParseLog.log(type: type, title: title, message: message, params: paramsDict, error: err)
        
        if TESTING == true {
            self.simpleAlert(title, defaultMessage: "Error type: \(type.rawValue) \(message ?? "")", error: err, completion: completion)
        }
    }
}
