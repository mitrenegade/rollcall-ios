//
//  RandomDrawingViewController.swift
//  rollcall
//
//  Created by Ren, Bobby on 2/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class RandomDrawingViewController: UIViewController {
    
    @IBOutlet var inputNumber: UITextField!
    @IBOutlet var switchRepeats: UISwitch!
    @IBOutlet var tableView: UITableView!
    
    internal var members: [Member]?
    var practice: Practice? {
        didSet {
            guard let attendances = practice?.attendances else { return }
            
            // TODO: eventually allow members to have multiple entries
            var mem: [Member] = []
            for attendance in attendances {
                if let member = attendance.member, Int(attendance.attended ?? 0) == AttendedStatus.Present.rawValue {
                    mem.append(member)
                }
            }
            self.members = mem
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.switchRepeats.setOn(false, animated: false)
        
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputNumber.inputAccessoryView = keyboardDoneButtonView
        
        self.inputNumber.text = "\(self.members?.count ?? 0)"
    }
    
    @IBAction func switchChanged(_ sender: UISwitch?) {
        self.dismissKeyboard()
    }
    
    @IBAction func didClickInfo(_ sender: UIButton?) {
        self.simpleAlert("What does Repeat mean?", message: "If Repeat is selected, the same person can be picked multiple times. Otherwise, the pool of names gets smaller each time, and you can only draw the same number of times as attendees.")
    }
    
    @IBAction func didClickDoDrawing(_ sender: UIButton?) {
        self.dismissKeyboard()
        
        let repeats = self.repeats ? "on": "off"
        print("drawing \(self.totalCount) times, repeat is \(repeats)")
        
        guard let members = self.members else {
            self.simpleAlert("Cannot do drawing", message: "There are currently no attendees at this event")
            return
        }
        
        var pool = [Member]()
        pool.append(contentsOf: members)
        self.doDrawingFromRemaining(remaining: self.totalCount, remainingMembers: pool, selected: nil) { (results) in
            print("results \(results)")
        }
    }
    
    var repeats: Bool {
        return self.switchRepeats.isOn
    }
    
    var totalCount: Int {
        guard let text = self.inputNumber.text, let count = Int(text) else {
            return 0
        }
        return count
    }
}

extension RandomDrawingViewController {
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        guard let text = self.inputNumber.text, let count = Int(text) else {
            self.inputNumber.text = "0"
            return
        }
        
        guard let members = self.members else {
            self.simpleAlert("Cannot do drawing", message: "There are currently no attendees at this event")
            return
        }
        
        if self.totalCount > members.count, !self.repeats {
            self.simpleAlert("Too many drawings", message: "Without repeats, you can only pick \(members.count) times")
            self.inputNumber.text = "\(members.count)"
        }
    }
}

extension RandomDrawingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttendanceCell", for: indexPath)
        
        guard let attendanceCell = cell as? AttendanceCell else { return cell }
        // Configure the cell...
//        guard let members = self.members, indexPath.row < members.count else { return cell }
//        let member = members[indexPath.row]
//        attendanceCell.configure(member: member, practice: self.practice, newAttendance: newAttendances[member], row: indexPath.row)
        return attendanceCell
    }
}

// MARK: Drawing
extension RandomDrawingViewController {
    
    func doDrawingFromRemaining(remaining: Int, remainingMembers: [Member], selected: [Member]?,completion: (([Member]?)->Void)) {
        var remainingMembers = remainingMembers
        var selected = selected
        if selected == nil {
            selected = [Member]()
        }
        
        if remaining == 0 {
            completion(selected)
            return
        }
        
        if remainingMembers.isEmpty {
            completion(selected)
            return
        }
        
        let index = Int(arc4random() % UInt32(remainingMembers.count))
        let member = remainingMembers[index]
        selected?.append(member)
        
        if !self.repeats {
            remainingMembers.remove(at: index)
        }
        
        self.doDrawingFromRemaining(remaining: remaining - 1, remainingMembers: remainingMembers, selected: selected, completion: completion)
    }
    /*
 #pragma mark Drawing
 -(void)doDrawingFromAttendees:(NSMutableArray *)attendees title:(NSString *)title message:(NSString *)message {
 NSArray *buttons = nil;
 if ([attendees count] > 0) {
 buttons = @[@"Pick a name and replace it", @"Pick a name without replacing it"];
 }
 else {
 message = @"No more attendees left to select from.";
 }
 [UIAlertView alertViewWithTitle:title message:message cancelButtonTitle:@"Close" otherButtonTitles:buttons onDismiss:^(int buttonIndex) {
 NSLog(@"Index %d", buttonIndex);
 int index = arc4random() % [attendees count];
 Attendance *attendance = (Attendance *)(attendees[index]);
 NSString *title = attendance.member.name;
 NSString *newMessage = message;
 if (buttonIndex == 0) {
 [self doDrawingFromAttendees:attendees title:title message:newMessage];
 }
 else if (buttonIndex == 1) {
 [attendees removeObject:attendance];
 if ([attendees count] == 0) {
 newMessage = @"No more attendees left to select from.";
 }
 [self doDrawingFromAttendees:attendees title:title message:newMessage];
 }
 
 } onCancel:nil];
 }
*/
}
