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
}
