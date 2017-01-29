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

extension UIViewController {
    func parseLog(type: TestAlertType, title: String?, message: String?, params: NSDictionary?, error: NSError?) {
        parseLog(typeString: type.rawValue, title: title, message: message, params: params, error: error)
    }

    // compatible with ObjC
    func parseLog(typeString: String, title: String?, message: String?, params: NSDictionary?, error: NSError?) {

        let object = PFObject(className: "TestLog")
        object.setValue(PFUser.current()?.objectId, forKey: "userId")
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]
        {
            object.setValue(version, forKey: "version")
        }
        if let build = Bundle.main.infoDictionary!["CFBundleVersion"]
        {
            object.setValue(build, forKey: "build")
        }
        object.setValue(typeString, forKey: "type")
        if let title = title {
            object.setValue(title, forKey: "title")
        }
        if let message = message {
            object.setValue(message, forKey: "message")
        }
        if let params = params {
            object.setValue(params, forKey:"params")
        }
        if let error = error {
            object.setValue(error.localizedDescription, forKey: "error")
        }
        object.saveInBackground()
    }
    
    func testAlert(_ title: String, message: String?, type: TestAlertType, error: Error? = nil, params: [String: Any]? = nil, completion: (() -> Void)? = nil) {
        
        self.parseLog(type: type, title: title, message: message, params: params, error: error)
        
        guard TEST else {
            return
        }
        
        self.simpleAlert(title, defaultMessage: "Error type: \(type.rawValue) \(message ?? "")", error: error as? NSError, completion: completion)
    }
}
