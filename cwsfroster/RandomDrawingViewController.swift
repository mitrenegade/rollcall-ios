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
    
    @IBOutlet var ratingsCanvas: UIView! // hack: for showing ratings at the right positiion
    @IBOutlet weak var constraintRatingsHeight: NSLayoutConstraint!
    lazy var rater: RatingViewController = {
        let rater = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RatingViewController") as! RatingViewController
        rater.delegate = self
        return rater
    }()
    
    var didShowRater: Bool = false
    
    internal var members: [Member]?
    var practice: Practice? {
        didSet {
            guard let attendances = practice?.attendances else { return }
            
            // TODO: eventually allow members to have multiple entries
            var mem: [Member] = []
            for attendance in attendances {
                if let member = attendance.member, Int(attendance.attended ?? 0) == AttendedStatus.Present.rawValue, let org = Organization.current, let orgMembers = org.members {
                    let filtered = orgMembers.filter({ (m) -> Bool in
                        if m.objectId == member.objectId {
                            return true
                        }
                        return false
                    })
                    if let m = filtered.first {
                        mem.append(m)
                    }
                }
            }
            self.members = mem
        }
    }
    var drawingResults: [Member]?
    
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
        
        ParseLog.log(typeString: "RandomDrawingScreen", title: nil, message: nil, params: nil, error: nil)
        self.ratingsCanvas.isUserInteractionEnabled = false
        self.constraintRatingsHeight.constant = 0
    }
    
    @IBAction func switchChanged(_ sender: UISwitch?) {
        self.dismissKeyboard()
        ParseLog.log(typeString: "RandomDrawingRepeatsSet", title: nil, message: nil, params: ["repeats": self.repeats], error: nil)
    }
    
    @IBAction func didClickInfo(_ sender: UIButton?) {
        self.simpleAlert("What does Repeat mean?", message: "If Repeat is selected, the same person can be picked multiple times. Otherwise, the pool of names gets smaller each time, and you can only draw the same number of times as attendees.")
        ParseLog.log(typeString: "RepeatInfoButtonClicked", title: nil, message: nil, params: nil, error: nil)
    }
    
    @IBAction func didClickDoDrawing(_ sender: UIButton?) {
        self.dismissKeyboard()
        
        let repeats = self.repeats ? "on": "off"
        print("drawing \(self.totalCount) times, repeat is \(repeats)")
        
        guard let members = self.members else {
            self.warnForDrawing()
            return
        }
        
        ParseLog.log(typeString: "RandomDrawingDone", title: nil, message: nil, params: ["repeats": self.repeats, "totalCount": self.totalCount], error: nil)
        
        var pool = [Member]()
        pool.append(contentsOf: members)
        self.drawingResults = nil
        self.doDrawingFromRemaining(remaining: self.totalCount, pool: pool, selected: nil) { (results) in
            print("results \(results)")
            self.drawingResults = results
            self.tableView.reloadData()
        }
        
        if !didShowRater {
            let forced = TEST
            if self.rater.showRatingsIfConditionsMet(from: self.ratingsCanvas, forced: forced) {
                self.constraintRatingsHeight.constant = 40

                self.ratingsCanvas.isUserInteractionEnabled = true
            }
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
    
    func warnForDrawing() {
        let title = "Cannot do drawing"
        let message = "There are currently no attendees at this event"
        self.simpleAlert(title, message: message)
        ParseLog.log(typeString: "RandomDrawingFailed", title: nil, message: nil, params: nil, error: nil)
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
            self.warnForDrawing()
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
        return self.drawingResults?.count ?? 0
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberCell", for: indexPath)
        
        guard let memberCell = cell as? MemberCell else { return cell }
        // Configure the cell...
        guard let members = self.drawingResults, indexPath.row < members.count else { return cell }
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
    
    func doDrawingFromRemaining(remaining: Int, pool: [Member], selected: [Member]?,completion: (([Member]?)->Void)) {
        var pool = pool
        var selected = selected
        if selected == nil {
            selected = [Member]()
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
        
        if !self.repeats {
            pool.remove(at: index)
        }
        
        self.doDrawingFromRemaining(remaining: remaining - 1, pool: pool, selected: selected, completion: completion)
    }
}

// MARK: Rater
extension RandomDrawingViewController: RatingDelegate {
    func didCloseRating() {
        self.ratingsCanvas.isUserInteractionEnabled = false
        self.constraintRatingsHeight.constant = 0
    }
    
    func goToFeedback() {
        
    }
}
