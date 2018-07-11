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
    
    internal var members: [FirebaseMember]?
    var practice: FirebaseEvent? {
        didSet {
            reloadData()
        }
    }
    var drawingResults: [FirebaseMember]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        switchRepeats.setOn(false, animated: false)
        
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        inputNumber.inputAccessoryView = keyboardDoneButtonView
        
        inputNumber.text = "\(members?.count ?? 0)"
        
        LoggingService.log(type: "RandomDrawingScreen")
    }
    
    fileprivate func reloadData() {
        guard let practice = practice else { return }
        let attendees = practice.attendees
        OrganizationService.shared.members { [weak self] (members, error) in
            self?.members = members.filter({ member in
                attendees.contains(member.id)
            }).sorted{
                guard let n1 = $0.name?.uppercased() else { return false }
                guard let n2 = $1.name?.uppercased() else { return true }
                return n1 < n2
            }
            self?.tableView.reloadData()
        }
    }

    
    @IBAction func switchChanged(_ sender: UISwitch?) {
        dismissKeyboard()
        LoggingService.log(type: "RandomDrawingRepeatsSet", info: ["repeats": repeats])
    }
    
    @IBAction func didClickInfo(_ sender: UIButton?) {
        simpleAlert("What does Repeat mean?", message: "If Repeat is selected, the same person can be picked multiple times. Otherwise, the pool of names gets smaller each time, and you can only draw the same number of times as attendees.")
        LoggingService.log(type: "RepeatInfoButtonClicked")
    }
    
    @IBAction func didClickDoDrawing(_ sender: UIButton?) {
        dismissKeyboard()
        
        let repeats = self.repeats ? "on": "off"
        print("drawing \(totalCount) times, repeat is \(repeats)")
        
        guard let members = members else {
            warnForDrawing()
            return
        }
        
        LoggingService.log(type: "RandomDrawingDone", info: ["repeats": repeats, "totalCount": totalCount])
        
        let pool = members[0..<members.count]
        drawingResults = nil
        doDrawingFromRemaining(remaining: totalCount, pool: pool, selected: nil) { (results) in
            print("results \(results)")
            self.drawingResults = results
            self.tableView.reloadData()
        }
    }
    
    var repeats: Bool {
        return switchRepeats.isOn
    }
    
    var totalCount: Int {
        guard let text = inputNumber.text, let count = Int(text) else {
            return 0
        }
        return count
    }
    
    func warnForDrawing() {
        let title = "Cannot do drawing"
        let message = "There are currently no attendees at this event"
        simpleAlert(title, message: message)
        LoggingService.log(type: "RandomDrawingFailed")
    }
}

extension RandomDrawingViewController {
    func dismissKeyboard() {
        view.endEditing(true)
        
        guard let text = inputNumber.text, let count = Int(text) else {
            inputNumber.text = "0"
            return
        }
        
        guard let members = members else {
            warnForDrawing()
            return
        }
        
        if totalCount > members.count, !repeats {
            simpleAlert("Too many drawings", message: "Without repeats, you can only pick \(members.count) times")
            inputNumber.text = "\(members.count)"
        }
    }
}

extension RandomDrawingViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drawingResults?.count ?? 0
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath)
        
        guard let memberCell = cell as? MemberCell else { return cell }
        // Configure the cell...
        guard let members = drawingResults, indexPath.row < members.count else { return cell }
        let member = members[indexPath.row]
        memberCell.configure(member: member, row: indexPath.row)
        
        if let label = memberCell.labelCount {
            label.text = "\(indexPath.row + 1)"
        }
        return memberCell
    }
}

// MARK: Drawing
extension RandomDrawingViewController {
    
    func doDrawingFromRemaining(remaining: Int, pool: ArraySlice<FirebaseMember>, selected: [FirebaseMember]?,completion: (([FirebaseMember]?)->Void)) {
        var pool = pool
        var selected = selected
        if selected == nil {
            selected = [FirebaseMember]()
        }
        
        if remaining == 0 {
            completion(selected)
            return
        }
        
        if pool.isEmpty {
            completion(selected)
            return
        }
        
        let index = Int(arc4random() % UInt32(pool.count))
        let member = pool[index]
        selected?.append(member)
        
        if !repeats {
            pool.remove(at: index)
        }
        
        doDrawingFromRemaining(remaining: remaining - 1, pool: pool, selected: selected, completion: completion)
    }
}
