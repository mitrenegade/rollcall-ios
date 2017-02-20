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
    }
    
    @IBAction func switchChanged(_ sender: UISwitch?) {
        print("nothing")
    }
    
    @IBAction func didClickInfo(_ sender: UIButton?) {
        self.simpleAlert("What does Repeat mean?", message: "If Repeat is selected, the same person can be picked multiple times. Otherwise, the pool of names gets smaller each time, and you can only draw the same number of times as attendees.")
    }
    
    @IBAction func didClickDoDrawing(_ sender: UIButton?) {
        self.view.endEditing(true)
        let repeats = self.repeats ? "on": "off"
        print("drawing \(self.totalCount) times, repeat is \(repeats)")
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
    
    /*
     -(void)didClickDrawing:(id)sender {
     NSString *title = @"Random drawing";
     NSString *message = @"Click to select one attendee at random";
     NSMutableArray *attendees = [[[[Organization current] attendances] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K != 0", @"attended"]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"practice = %@", self.practice.objectId]]; //[[Practice where:@{@"title":dateString}] all];
     for (Attendance *a in attendees) {
     NSLog(@"Attendance %@, attended %@", a, a.attended);
     }
     
     [self doDrawingFromAttendees:attendees title:title message:message];
     }
     */
}

extension RandomDrawingViewController: UITextFieldDelegate {
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let text = textField.text, let count = Int(text), count > 0 else {
            textField.text = "0"
            return
        }
        
        if !self.repeats {
            // TODO
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
//        guard let members = Organization.current?.members, indexPath.row < members.count else { return cell }
//        let member = members[indexPath.row]
//        attendanceCell.configure(member: member, practice: self.practice, newAttendance: newAttendances[member], row: indexPath.row)
        return attendanceCell
    }
}

extension RandomDrawingViewController: UITableViewDelegate {
    
}
