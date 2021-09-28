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
    private let attendanceView = UIImageView()
    private let attendanceLabel = UILabel()

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
            $0.bottom.equalToSuperview().offset(-8)
            $0.height.equalTo(30)
        }

        if FeatureManager.shared.hasPrepopulateAttendance {
            contentView.addSubview(attendanceLabel)
            attendanceLabel.snp.makeConstraints {
                $0.leading.equalTo(nameLabel.snp.trailing).offset(8)
                $0.top.equalToSuperview().offset(8)
                $0.trailing.equalToSuperview().offset(-8)
                $0.bottom.equalToSuperview().offset(-8)
                $0.height.equalTo(30)
            }
        } else {
            contentView.addSubview(attendanceView)
            attendanceView.snp.makeConstraints {
                $0.leading.equalTo(nameLabel.snp.trailing).offset(8)
                $0.top.equalToSuperview().offset(8)
                $0.trailing.equalToSuperview().offset(-8)
                $0.bottom.equalToSuperview().offset(-8)
                $0.height.equalTo(30)
                $0.width.equalTo(30)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Common cell configuration
    private func configure(member: FirebaseMember, row: Int) {
        nameLabel.text = member.displayName

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

    // MARK: - Standard
    func configure(member: FirebaseMember, attended: AttendedStatus, row: Int) {
        configure(member: member, row: row)

        if !FeatureManager.shared.hasPrepopulateAttendance {
            attendanceView.image = attendedStatusImage(attended)
        }
    }

    private func attendedStatusImage(_ attended: AttendedStatus) -> UIImage? {
        if attended != AttendedStatus.None {
            return UIImage(named: "checked")
        } else {
            return UIImage(named: "unchecked")
        }
    }

    // MARK: - Plus
    func configure(attendance: Attendance, row: Int) {
        guard FeatureManager.shared.hasPrepopulateAttendance else {
            return
        }

        configure(member: attendance.member, row: row)

        attendanceLabel.text = attendance.status.rawValue
    }
}
