//
//  MemberCell.swift
//  rollcall
//
//  Created by Bobby Ren on 2/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

class MemberCell: UITableViewCell {

    @IBOutlet var photoView: RAImageView!
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
        
        if let url = member.photoUrl {
            photoView.imageUrl = url
            photoView.image = member.photo
        } else {
            photoView.image = UIImage(named: "user1") // [UIImage imageNamed:@"user1"];
            photoView.imageUrl = nil
        }

        if member.isInactive {
            labelName.alpha = 0.5;
        }
        else {
            labelName.alpha = 1;
        }

    }
}
