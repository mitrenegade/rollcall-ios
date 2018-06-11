//
//  OnsiteSignupViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/11/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

extension OnsiteSignupViewController {
    func didClickSignup(_ sender: AnyObject?) {
        guard let name = inputName.text, !name.isEmpty else {
            self.simpleAlert("Please enter a name", message: nil)
            return
        }
        
        guard let email = inputEmail.text, !email.isEmpty && !email.isValidEmail() else {
            self.simpleAlert("Please enter a valid email", message: nil)
            return
        }
        
        self.buttonSave.isEnabled = false
        
        OrganizationService.shared.createMember(email: email, name: name, notes: inputAbout.text, status: .Active) { [weak self] (member, error) in
            
            // BOBBY TODO
//            if let photo = self.addedPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
//                member.photo = PFFile(data:data)
//            }
            
            if let member = member {
                self?.notify("member:updated", object: nil, userInfo: nil)
                ParseLog.log(typeString: "OnsiteSignup", title: member.id, message: nil, params: ["photo": self?.addedPhoto != nil], error: nil)
                
                // add attendance
                self?.practice.addAttendance(for: member)
                
                // enable button and reset form
                self?.buttonSave.isEnabled = true
                self?.addedAttendees.insert(member, at: 0)
                self?.labelAttendanceCount.text = "New attendees: \(self?.addedAttendees.count)"
                
                self?.labelWelcome.alpha = 1
                self?.labelWelcome.text = "Welcome \(member.name ?? "")"
                
                UIView.animate(withDuration: 0.25, delay: 2, options: UIViewAnimationOptions.curveLinear, animations: {
                    self?.labelWelcome.alpha = 0
                }, completion: nil)
                
                self?.reset()
            } else if let error = error {
                print("Error creating member")
                self?.simpleAlert("Could not sign up user", message: "There was an error adding \(name) to this event. Please add them manually by editing event attendees")
            }
        }
    }

    func reset(){
        self.view.endEditing(true)
        self.inputEmail.text = nil;
        self.inputName.text = nil;
        self.inputAbout.text = nil;

        self.buttonPhoto.setImage(UIImage.init(named: "add_user"), for: .normal)
        self.buttonPhoto.layer.cornerRadius = 0
        self.constraintTopOffset.constant = 0
        self.buttonSave.isEnabled = true
    }
}

extension OnsiteSignupViewController: CameraControlsDelegate {
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        self.takePhoto()
    }
    
    func takePhoto() {
        self.view.endEditing(true)
        
        let controller = CameraOverlayViewController(
            nibName:"CameraOverlayViewController",
            bundle: nil
        )
        controller.delegate = self
        controller.view.frame = UIScreen.main.bounds
        controller.takePhoto(from: self)
        
        ParseLog.log(typeString: "EditOnsiteSignupPhoto", title: nil, message: nil, params: nil, error: nil)
    }
    
    func didTakePhoto(image: UIImage) {
        self.buttonPhoto.setImage(image, for: .normal)
        buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        self.addedPhoto = image
        self.dismissCamera()
    }
    
    func dismissCamera() {
        self.dismiss(animated: true, completion: nil)
    }
}
