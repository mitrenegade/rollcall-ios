//
//  MemberInfoViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit

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
            let image = UIImage.init(data: photo)
            buttonPhoto.setImage(image, for: .normal)
            buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        }
        newPhoto = nil
        inputNotes.text = nil
        
        self.refresh()
    }
    
    func refresh() {
        guard let member = member else {
            self.title = "New member"
            return
        }
        
        self.title = "Edit member"
        if let name = member.name {
            self.inputName.text = name
        }
        if let email = member.email {
            self.inputEmail.text = email
        }
        if let notes = member.notes {
            self.inputNotes.text = notes
        }
        self.switchInactive.isOn = member.isInactive()
        
        
    }

    @IBAction func didClickClose(_ sender: AnyObject?) {
        
    }
    
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        
    }

    @IBAction func didClickSwitch(_ sender: AnyObject?) {
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
