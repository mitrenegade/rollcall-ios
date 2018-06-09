//
//  AppDelegate+Utils.swift
//  rollcall
//
//  Created by Bobby Ren on 2/3/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//
//  Move AppDelegate files over until we get rid of core data

import Foundation
import Parse
import Firebase

extension AppDelegate {
    @objc func registerParse() {
        let configuration = ParseClientConfiguration {
            $0.applicationId = PARSE_APP_ID
            $0.clientKey = PARSE_CLIENT_KEY
            //$0.server = LOCAL_TEST ? PARSE_SERVER_URL_LOCAL : PARSE_SERVER_URL
            $0.server = PARSE_SERVER
        }
        
        Parse.initialize(with: configuration)
        /*
        Review.registerSubclass()
        Call.registerSubclass()
        User.registerSubclass()
        PaymentMethod.registerSubclass()
        */
    }
    
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
}
