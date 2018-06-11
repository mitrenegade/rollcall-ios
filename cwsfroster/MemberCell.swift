//
//  MemberCell.swift
//  rollcall
//
//  Created by Bobby Ren on 2/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class MemberCell: UITableViewCell {

    @IBOutlet var photoView: UIImageView!
    @IBOutlet var labelName: UILabel!
    
    @IBOutlet var labelCount: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(member: FirebaseMember, row: Int) {
        labelName.font = UIFont.systemFont(ofSize: 16)
        labelName.textColor = UIColor.darkGray
        labelName.text = member.name
        
        self.tag = row; // make sure photo loads for correct cell
        photoView.image = UIImage(named: "user1") // [UIImage imageNamed:@"user1"];
        
        if let photoUrl = member.photoUrl {
            // BOBBY TODO
//            photo.getDataInBackground(block: { (data, error) in
//                if self.tag != row {
//                    return
//                }
//                if let data = data {
//                    let image = UIImage(data: data)
//                    self.photoView.image = image
//                }
//            })
        }

        if member.isInactive {
            labelName.alpha = 0.5;
        }
        else {
            labelName.alpha = 1;
        }

    }
}
