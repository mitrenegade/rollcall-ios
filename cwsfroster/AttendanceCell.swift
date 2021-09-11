//
//  AttendanceCell.swift
//  rollcall
//
//  Created by Bobby Ren on 2/9/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import SnapKit

class AttendanceCell: UITableViewCell {

    private let nameLabel = UILabel()
    private let photoView = RAImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(photoView)
        photoView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(30)
            $0.height.equalTo(30)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.leading.equalTo(photoView.snp.trailing).offset(8)
            $0.top.equalToSuperview().offset(8)
            $0.trailing.equalToSuperview().offset(-8)
            $0.bottom.equalToSuperview().offset(-8)
            $0.height.equalTo(30)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(member: FirebaseMember, attendance: AttendedStatus, row: Int) {
        nameLabel.text = member.displayName
        
        let unchecked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        unchecked.image = UIImage(named: "unchecked")
        self.accessoryView = unchecked
        if attendance != AttendedStatus.None {
            let checked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            checked.image = UIImage(named: "checked")
            self.accessoryView = checked
        }
        
        self.tag = row; // make sure photo loads for correct cell

        if let url = member.photoUrl {
            photoView.imageUrl = url
            photoView.image = member.photo
            photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
        } else {
            photoView.image = UIImage(named: "user1") // [UIImage imageNamed:@"user1"];
            photoView.imageUrl = nil
        }

        if member.isInactive {
            nameLabel.alpha = 0.5;
        }
        else {
            nameLabel.alpha = 1;
        }
    }
}
