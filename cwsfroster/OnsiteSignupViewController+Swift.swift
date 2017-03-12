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
        
        if let email = inputEmail.text, !email.isEmpty && !email.isValidEmail() {
            self.simpleAlert("Please enter a valid email", message: nil)
            return
        }
        
        self.buttonSave.isEnabled = false
        
        let member = Member()
        member.organization = Organization.current
        member.name = name
        member.email = inputEmail.text
        
        if let photo = self.addedPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
            member.photo = PFFile(data:data)
        }
        
        self.notify("member:updated", object: nil, userInfo: nil)
        
        member.saveInBackground { (result, error) in
            Organization.current?.members?.insert(member, at: 0)
            ParseLog.log(typeString: "OnsiteSignup", title: member.objectId, message: nil, params: ["photo": self.addedPhoto != nil], error: nil)
        }
        
        Attendance.saveNewAttendanceFor(member: member, practice: self.practice, saveToParse: true) { (attendance, error) in
            self.buttonSave.isEnabled = true
            if let error = error {
                self.simpleAlert("Could not sign up user", message: "There was an error adding \(member.name) to this event. Please add them manually by editing event attendees")
                return
            }

            self.addedAttendees.insert(member, at: 0)
            self.labelAttendanceCount.text = "New attendees: \(self.addedAttendees.count)"
            
            self.labelWelcome.alpha = 1
            self.labelWelcome.text = "Welcome \(member.name ?? "")"
            
            UIView.animate(withDuration: 0.25, delay: 2, options: UIViewAnimationOptions.curveLinear, animations: {
                self.labelWelcome.alpha = 0
            }, completion: nil)
            
            self.reset()
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

extension OnsiteSignupViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        self.takePhoto()
    }
    
    func takePhoto() {
    
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraDevice = .front // use front camera because member is probably entering own information
        }
        else if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            picker.sourceType = .photoLibrary
        }
        else {
            picker.sourceType = .savedPhotosAlbum
        }
        
        self.present(picker, animated: true, completion: nil)
        ParseLog.log(typeString: "EditOnsiteSignupPhoto", title: nil, message: nil, params: nil, error: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let img = info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]
        guard let photo = img as? UIImage else { return }
        self.buttonPhoto.setImage(photo, for: .normal)
        picker.dismiss(animated: true, completion: nil)
        buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        self.addedPhoto = photo
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
