//
//  AttendanceCell.swift
//  rollcall
//
//  Created by Bobby Ren on 2/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class AttendanceCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var photoView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(member: Member, practice: Practice?, newAttendance: Attendance?, row: Int) {
        nameLabel.text = member.name
        
        let unchecked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        unchecked.image = UIImage(named: "unchecked")
        self.accessoryView = unchecked
        if let practice = practice, let attendance = practice.attendanceFor(member: member), let attended = attendance.attended, attended.intValue != AttendedStatus.None.rawValue {
            let checked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            checked.image = UIImage(named: "checked")
            self.accessoryView = checked
        }
        else if let attendance = newAttendance, let attended = attendance.attended, attended.intValue != AttendedStatus.None.rawValue {
            let checked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            checked.image = UIImage(named: "checked")
            self.accessoryView = checked
        }
        
        self.tag = row; // make sure photo loads for correct cell
        photoView.image = UIImage(named: "user1") // [UIImage imageNamed:@"user1"];
        
        if let photo = member.photo {
            photo.getDataInBackground(block: { (data, error) in
                if self.tag != row {
                    return
                }
                if let data = data {
                    let image = UIImage(data: data)
                    self.photoView.image = image
                }
            })
        }
        
        if member.isInactive {
            nameLabel.alpha = 0.5;
        }
        else {
            nameLabel.alpha = 1;
        }
    }
}
