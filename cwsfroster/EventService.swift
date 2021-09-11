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

    func createEvent(_ name: String,
                     date: Date,
                     notes: String? = nil,
                     details: String? = nil,
                     organization: String,
                     cost: Double? = nil,
                     recurrence: Date.Recurrence = .none,
                     recurrenceEndDate: Date? = nil,
                     completion:@escaping (FirebaseEvent?, NSError?) -> Void) {
        
        print ("Create events")

        guard UserService.shared.isLoggedIn else { return }
        
        let newEventRef = firRef.child("events").child(FirebaseAPIService.uniqueId())
        
        var params: [String: Any] = ["title": name,
                                     "date": date.timeIntervalSince1970,
                                     "organization": organization,
                                     "createdAt": Date().timeIntervalSince1970,
                                     "recurrence": recurrence.rawValue]
        if let notes = notes {
            params["notes"] = notes
        }
        if let details = details {
            params["details"] = details
        }
        if let cost = cost {
            params["cost"] = cost
        }
        if recurrence != .none, let recurrenceEndDate = recurrenceEndDate {
            params["recurrenceEndDate"] = recurrenceEndDate.timeIntervalSince1970
        }

        newEventRef.setValue(params) { (error, ref) in
            if let error = error as NSError? {
                print(error)
                completion(nil, error)
            } else {
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    guard snapshot.exists() else {
                        completion(nil, nil)
                        return
                    }
                    guard UserService.shared.currentUser != nil else {
                        completion(nil, nil)
                        return
                    }
                    let event = FirebaseEvent(snapshot: snapshot)

                    completion(event, nil)
                })
            }
        }
    }

    func deleteEvent(_ event: FirebaseEvent, completion:@escaping (Result<Void, Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        let ref = firRef.child("events").child(event.id)
        ref.setValue(nil) { (error, ref) in
            if let error = error {
                print(error)
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
