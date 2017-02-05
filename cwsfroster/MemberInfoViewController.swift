//
//  MemberInfoViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
/*
@objc protocol MemberDelegate: class {

    func close()
    func saveNewMember(name: String, status: MemberStatus, photo: UIImage)
    func updateMember(member: Member)
}
*/

class MemberInfoViewController: UIViewController {
    
    @IBOutlet var buttonPhoto: UIButton!
    @IBOutlet var inputName: UITextField!
    @IBOutlet var inputEmail: UITextField!
    @IBOutlet var inputNotes: UITextView!
    @IBOutlet var switchInactive: UISwitch!
    @IBOutlet var labelPaymentWarning: UILabel!
    @IBOutlet var buttonPayment: UIButton!

    var member: Member?
    var delegate: MemberDelegate?
    var newPhoto: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let member = member, let photo = member.photo {
//            let image = UIImage.init(data: photo)
//            buttonPhoto.setImage(image, for: .normal)
//            buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        }
        newPhoto = nil
        inputNotes.text = nil
        
        if let member = member {
            self.title = "Edit member"
        } else {
            self.title = "New member"
            self.member = Member()
        }
        self.refresh()
    }
    
    func refresh() {
        guard let member = self.member else { return }
        
        if let name = member.name {
            self.inputName.text = name
        }
        if let email = member.email {
            self.inputEmail.text = email
        }
        if let notes = member.notes {
            self.inputNotes.text = notes
        }
        self.switchInactive.isOn = member.isInactive
    }
    
    func close() {
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.close()
    }
    
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        
    }

    @IBAction func didClickSwitch(_ sender: AnyObject?) {
        
    }
}

