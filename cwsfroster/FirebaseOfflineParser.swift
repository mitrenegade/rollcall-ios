//
//  FirebaseOfflineParser.swift
//  rollcall
//
//  Created by Bobby Ren on 6/9/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class FirebaseOfflineParser: NSObject {
    class func loadData() {
        let filePath = Bundle.main.path(forResource: "rollcall-and-random-dev-export", ofType: "json")
        let stream = InputStream(fileAtPath: filePath!)
        let json = try! JSONSerialization.jsonObject(with: stream!, options: [])
        print("json: \(json)")
    }
}
