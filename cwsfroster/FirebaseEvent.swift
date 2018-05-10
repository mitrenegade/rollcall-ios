//
//  EventModel.swift
// Balizinha
//
//  Created by Bobby Ren on 5/13/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

fileprivate let formatter = DateFormatter()

class FirebaseEvent: FirebaseBaseModel {
    var service = EventService.shared
    
    var name: String? {
        get {
            return self.dict["name"] as? String
        }
        set {
            self.dict["name"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var date: Date? {
        get {
            if let val = self.dict["date"] as? TimeInterval {
                return Date(timeIntervalSince1970: val)
            }
            return nil // what is a valid date equivalent of TBD?
        }
        set {
            self.dict["date"] = newValue?.timeIntervalSince1970
            self.firebaseRef?.updateChildValues(self.dict)
        }
    }

    var notes: String? {
        get {
            return self.dict["notes"] as? String
        }
        set {
            self.dict["notes"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
    
    var details: String? {
        get {
            return self.dict["details"] as? String
        }
        set {
            self.dict["details"] = newValue
            self.firebaseRef?.updateChildValues(self.dict)
        }
        
    }
}

// Utils
extension Event {
    func dateString(_ date: Date) -> String {
        //return "\((date as NSDate).day()) \(months[(date as NSDate).month() - 1]) \((date as NSDate).year())"
        return date.dateStringForPicker()
    }
    
    func timeString(_ date: Date) -> String {
        /*
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let time = formatter.string(from: date)
        return "\(time)"
        */
        return date.timeStringForPicker()
    }
    
    var numPlayers: Int {
        let users = self.users
        print("users: \(users.count)")
        return users.count
    }
    
    var users: [String] {
        guard let usersForEvents = self.service.usersForEvents else { return [] }
        if let results = usersForEvents[self.id] as? [String: AnyObject] {
            let filtered = results.filter({ (arg) -> Bool in
                
                let (key, val) = arg
                return val as! Bool
            })
            let userIds = filtered.map({ (arg) -> String in
                
                let (key, val) = arg
                return key
            })
            return userIds
        }
        return []
    }
    
    func containsUser(_ user: User) -> Bool {
        return self.users.contains(user.uid)
    }
    
    var isFull: Bool {
        return self.maxPlayers == self.numPlayers
    }
    
    var isPast: Bool {
        if let endTime = self.endTime {
            return (ComparisonResult.orderedAscending == endTime.compare(Date())) //event time happened before current time
        }
        else {
            return false // false means TBD
        }
    }
    
    var userIsOrganizer: Bool {
        guard let owner = self.owner else { return false }
        guard let user = AuthService.currentUser else { return false }
        
        return user.uid == owner
    }
    
    var locationString: String? {
        if let city = self.city, let state = self.state {
            return "\(city), \(state)"
        }
        else if let city = self.city {
            return city
        }
        else if let lat = lat, let lon = lon {
            return "\(lat), \(lon)"
        }
        return nil
    }
}

extension Event {
    //***************** hack: for test purposes only
    class func randomEvent() -> Event {
        let event = Event()
        let hours: Int = Int(arc4random_uniform(72))
        event.dict = ["type": event.randomType() as AnyObject, "place": event.randomPlace() as AnyObject, "startTime": (Date().timeIntervalSince1970 + Double(hours * 3600)) as AnyObject, "info": "Randomly generated event" as AnyObject]
        return event
    }
    
    func randomType() -> String {
        let types: [EventType] = [.event3v3]
        let random = Int(arc4random_uniform(UInt32(types.count)))
        return types[random].rawValue
    }
    
    func randomPlace() -> String {
        let places = ["Boston", "New York", "Philadelphia", "Florida"]
        let random = Int(arc4random_uniform(UInt32(places.count)))
        return places[random]
    }
}
