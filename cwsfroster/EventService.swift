//
//  EventService.swift
// Balizinha
//
//  Created by Bobby Ren on 5/12/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//
// EventService usage:
// var service = EventService.shared
// service.getEvents()

import UIKit
import Firebase
import RxSwift

var _usersForEvents: [String: AnyObject]?
var _events: [FirebaseEvent]?

class EventService: NSObject {
    static let shared: EventService = EventService()

    func createEvent(_ name: String, date: Date, notes: String? = nil, details: String? = nil, organization: String, completion:@escaping (FirebaseEvent?, NSError?) -> Void) {
        
        print ("Create events")

        guard let user = AuthService.currentUser else { return }
        
        let eventRef = firRef.child("events") // this references the endpoint lotsports.firebase.com/events/
        let id = FirebaseAPIService.uniqueId()
        let newEventRef = eventRef.child(id) // this generates an autoincremented event endpoint like lotsports.firebase.com/events/<uniqueId>
        
        var params: [String: Any] = ["title": name, "date": date.timeIntervalSince1970, "organization": organization]
        if let notes = notes {
            params["notes"] = notes
        }
        if let details = details {
            params["details"] = details
        }

        newEventRef.setValue(params) { (error, ref) in
            if let error = error as? NSError {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion(nil, nil)
                        return
                    }
                    guard let user = AuthService.currentUser else {
                        completion(nil, nil)
                        return
                    }
                    let event = FirebaseEvent(snapshot: snapshot)

                    completion(event, nil)
                })
            }
        }
    }
}
