//
//  MemberInfoViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class MemberInfoViewController: UIViewController {
    
    @IBOutlet var photoView: UIImageView!
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
    var isCreatingMember = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        newPhoto = nil
        inputNotes.text = nil
        
        if let member = member {
            self.title = "Edit member"
            self.navigationItem.rightBarButtonItem = nil
            
            if let photo = member.photo {
                photo.getDataInBackground(block: { (data, error) in
                    if let data = data {
                        let image = UIImage(data: data)
                        self.photoView.image = image
                        self.photoView.layer.cornerRadius = self.buttonPhoto.frame.size.width / 2
                    }
                })
            }
            self.switchInactive.isOn = member.isInactive
        } else {
            self.title = "New member"
            self.isCreatingMember = true
        }
        self.setupTextView()
        self.refresh()
    }
    
    func setupTextView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.done, target: self, action: #selector(NotesViewController.dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputNotes.inputAccessoryView = keyboardDoneButtonView
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
        if let member = member {
            self.saveMember()
        }
        if self.navigationController?.viewControllers[0] == self {
            self.navigationController?.dismiss(animated: true, completion: { 
                if let member = self.member {
                    if !self.isCreatingMember {
                        var params = [String:Any]()
                        if let name = self.member?.name { params["name"] = name }
                        if let email = self.member?.email { params["email"] = email }
                        ParseLog.log(typeString: "MemberUpdated", title: self.member?.objectId, message: nil, params: params as NSDictionary?, error: nil)
                    }
                    self.delegate?.didUpdateMember(member)
                }
            })
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func saveMember() {
        member?.saveInBackground(block: { (success, error) in
            if success {
                var params = [String:Any]()
                if let name = self.member?.name { params["name"] = name }
                if let email = self.member?.email { params["email"] = email }
                ParseLog.log(typeString: "MemberCreated", title: self.member?.objectId, message: nil, params: params as NSDictionary?, error: nil)
                
                self.delegate?.didUpdateMember(self.member)
            }
            else {
                self.simpleAlert("Could not create member", defaultMessage: "There was an error adding the member", error: error as? NSError)
            }
        })
    }

    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.view.endEditing(true)
        if let text = self.inputEmail.text, text.characters.count > 0 {
            if !text.isValidEmail() {
                self.simpleAlert("Invalid email", message: "Please enter a valid email if it exists.")
                return
            }
        }

        if let photo = self.newPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
            member?.photo = PFFile(data:data)
        }

        self.close()
    }
    
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        self.takePhoto()
    }

    @IBAction func didClickSwitch(_ sender: AnyObject?) {
        if let member = self.member {
            member.status = self.switchInactive.isOn ? NSNumber(value: MemberStatus.Inactive.rawValue): NSNumber(value: MemberStatus.Active.rawValue)
            member.saveInBackground()
        }
    }
    
    @IBAction func didClickSave(_ sender: AnyObject?) {
        if let text = self.inputEmail.text, text.characters.count > 0 {
            if !text.isValidEmail() {
                self.simpleAlert("Invalid email", message: "Please enter a valid email if it exists.")
                return
            }
        }
        
        if member == nil {
            member = Member()
            member?.organization = Organization.current
            
            // without reloading from the web, make sure org knows of new member
            Organization.current?.members?.insert(member!, at: 0)
        }
        if let text = self.inputName.text, text.characters.count > 0 {
            self.member?.name = text
        }
        if let text = self.inputEmail.text, text.characters.count > 0 {
            self.member?.email = text
        }
        if let text = inputNotes.text, text.characters.count > 0 {
            member?.notes = text
        }
        if let photo = self.newPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
            member?.photo = PFFile(data:data)
        }
        member?.status = self.switchInactive.isOn ? NSNumber(value: MemberStatus.Inactive.rawValue): NSNumber(value: MemberStatus.Active.rawValue)

        self.close()
    }
}

// MARK: UITextFieldDelegate
extension MemberInfoViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let member = self.member else { return }
        if textField == inputName {
            if let text = textField.text, text.characters.count > 0 {
                member.name = text
            }
            else {
                textField.text = member.name
            }
        }
        else if textField == inputEmail {
            if let text = textField.text, text.characters.count > 0 {
                if text.isValidEmail() {
                    member.email = text
                }
                else {
                    textField.text = member.email
                }
            }
        }
        
        textField.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension MemberInfoViewController: UITextViewDelegate {
    func dismissKeyboard() {
        self.view.endEditing(true)
        
        if let member = self.member {
            member.notes = self.inputNotes.text
        }
    }
}

// MARK: Camera
extension MemberInfoViewController: CameraControlsDelegate {
    func takePhoto() {
        self.view.endEditing(true)

        let controller = CameraOverlayViewController(
            nibName:"CameraOverlayViewController",
            bundle: nil
            )
        controller.delegate = self
        controller.view.frame = self.view.frame
        controller.takePhoto(from: self)
        
        // add overlayview
        ParseLog.log(typeString: "EditMemberPhoto", title: member?.objectId, message: nil, params: nil, error: nil)
    }

    func didTakePhoto(image: UIImage) {
        self.buttonPhoto.setImage(image, for: .normal)
        buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        self.newPhoto = image
        self.dismissCamera()
    }

    func dismissCamera() {
        self.dismiss(animated: true, completion: nil)
    }
}
