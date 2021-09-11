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
                     completion:@escaping (FirebaseEvent?, NSError?) -> Void) {
        
        print ("Create events")

        guard UserService.shared.isLoggedIn else { return }
        
        let newEventRef = firRef.child("events").child(FirebaseAPIService.uniqueId())
        
        var params: [String: Any] = ["title": name, "date": date.timeIntervalSince1970, "organization": organization, "createdAt": Date().timeIntervalSince1970]
        if let notes = notes {
            params["notes"] = notes
        }
        if let details = details {
            params["details"] = details
        }
        if let cost = cost {
            params["cost"] = cost
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

    enum EventError: Error {
        case invalidEvent
    }

    func attendances(for event: FirebaseEvent, completion: @escaping  (Result<[FirebaseAttendance], Error>) -> Void) {
        guard UserService.shared.isLoggedIn else { return }

        let ref = firRef.child("eventAttendances").child(event.id)
        ref.observe(.value) { snapshot in
            guard snapshot.exists() else {
                completion(.failure(EventError.invalidEvent))
                return
            }

            var results: [FirebaseAttendance] = []
            if let allObjects =  snapshot.children.allObjects as? [DataSnapshot] {
                for dict: DataSnapshot in allObjects {
                    let object = FirebaseAttendance(snapshot: dict)
                    results.append(object)
                }
            }
            completion(.success(results))
        }

    }
}
