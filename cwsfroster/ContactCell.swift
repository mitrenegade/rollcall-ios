//
//  ContactCell.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    func configure(name: String?, email: String?, selected: Bool) {
        textLabel?.text = name ?? email ?? "Anon"
        detailTextLabel?.text = email
        
        if selected {
            let checked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            checked.image = UIImage(named: "checked")
            self.accessoryView = checked
        } else {
            let unchecked = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            unchecked.image = UIImage(named: "unchecked")
            self.accessoryView = unchecked
        }
    }
}
