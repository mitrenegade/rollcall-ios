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

    var member: FirebaseMember?
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
            
            if let photo = member.photoUrl {
                // BOBBY TODO
//                photo.getDataInBackground(block: { (data, error) in
//                    if let data = data {
//                        let image = UIImage(data: data)
//                        self.photoView.image = image
//                        self.photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
//                    }
//                })
            }
            self.switchInactive.isOn = member.isInactive
        } else {
            self.title = "New member"
            self.isCreatingMember = true
            
            navigationItem.leftBarButtonItem?.title = "Cancel"
        }
        self.setupTextView()
        self.refresh()
    }
    
    func setupTextView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItemStyle.done, target: self, action: #selector(dismissKeyboard))
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
        if self.navigationController?.viewControllers[0] == self {
            self.navigationController?.dismiss(animated: true, completion: { 
            })
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.view.endEditing(true)
        if isCreatingMember {
            close()
        } else {
            saveMember()
        }
    }
    
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        self.takePhoto()
    }

    @IBAction func didClickSave(_ sender: AnyObject?) {
        saveMember()
    }
    
    fileprivate func saveMember() {
        guard let email = self.inputEmail.text, !email.isEmpty, email.isValidEmail() else {
            self.simpleAlert("Invalid email", message: "Please enter a valid email if it exists.")
            return
        }
        let name = self.inputName.text
        let notes = inputNotes.text
        
        let status: MemberStatus = switchInactive.isOn ? .Inactive : .Active
        
        if isCreatingMember {
            OrganizationService.shared.createMember(email: email, name: name, notes: notes, status: status) { [weak self] (member, error) in
                
                var params = [String:Any]()
                if let member = member {
                    if let name = member.name { params["name"] = name }
                    if let email = member.email { params["email"] = email }
                    ParseLog.log(typeString: "MemberCreated", title: member.id, message: nil, params: params as NSDictionary?, error: nil)

                    self?.delegate?.didUpdateMember(member)
                    if let photo = self?.newPhoto, let data = UIImageJPEGRepresentation(photo, 0.8) {
                        // BOBBY TODO: upload photo
                        self?.close()
                    } else {
                        self?.close()
                    }
                } else {
                    self?.simpleAlert("Could not create member", message: "The member info could not be saved.", completion: {
                        self?.close()
                    })
                }
            }
        } else if let member = member {
            self.delegate?.didUpdateMember(member)
            var params = [String:Any]()
            if let name = self.member?.name { params["name"] = name }
            if let email = self.member?.email { params["email"] = email }
            ParseLog.log(typeString: "MemberUpdated", title: self.member?.id, message: nil, params: params as NSDictionary?, error: nil)
            close()
        }
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
        view.endEditing(true)
        
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
        ParseLog.log(typeString: "EditMemberPhoto", title: member?.id, message: nil, params: nil, error: nil)
    }

    func didTakePhoto(image: UIImage) {
        self.photoView.image = image
        self.photoView.layer.cornerRadius = photoView.frame.size.width / 2
        self.newPhoto = image
        self.dismissCamera()
    }

    func dismissCamera() {
        self.dismiss(animated: true, completion: nil)
    }
}
