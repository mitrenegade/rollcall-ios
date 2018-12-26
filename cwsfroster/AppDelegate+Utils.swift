//
//  AppDelegate+Utils.swift
//  rollcall
//
//  Created by Bobby Ren on 2/3/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
//  Move AppDelegate files over until we get rid of core data

import Foundation
import Firebase

extension AppDelegate {

    @objc func registerFirebase() {
        // Firebase
        // Do not include infolist in project: https://firebase.google.com/docs/configure/#reliable-analytics
        let plistFilename = "GoogleService-Info\(TESTING ? "-dev" : "")"
        let filePath = Bundle.main.path(forResource: plistFilename, ofType: "plist")
        assert(filePath != nil, "File doesn't exist")
        if let path = filePath, let fileopts = FirebaseOptions.init(contentsOfFile: path) {
            FirebaseApp.configure(options: fileopts)
        }
        
        // handle firebase user
        let userDefaults = UserDefaults.standard
        if userDefaults.value(forKey: "appFirstTimeOpened") == nil {
            //if app is first time opened then it will be nil
            userDefaults.setValue(true, forKey: "appFirstTimeOpened")
            // signOut from FIRAuth
            do {
                try Auth.auth().signOut()
            }catch {
                print("signout didn't work")
            }
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true), components.scheme == "rollcall" {
            var pathComponents = components.path.components(separatedBy: "/")
            print("url: \(url)\ncomponents: \(components)\npath: \(pathComponents)")
        }
        return false
    }
}
