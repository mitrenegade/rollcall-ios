//
//  MemberInfoViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RACameraHelper

class MemberInfoViewController: UIViewController {
    
    @IBOutlet var photoView: RAImageView!
    @IBOutlet var buttonPhoto: UIButton!
    @IBOutlet var inputName: UITextField!
    @IBOutlet var inputEmail: UITextField!
    @IBOutlet var inputNotes: UITextView!
    @IBOutlet var switchInactive: UISwitch!
    @IBOutlet var labelPaymentWarning: UILabel!
    @IBOutlet var buttonPayment: UIButton!
    let cameraHelper = CameraHelper()
    
    var member: FirebaseMember?
    var delegate: MemberDelegate?
    var newPhoto: UIImage?
    var isCreatingMember = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraHelper.delegate = self

        // Do any additional setup after loading the view.
        newPhoto = nil
        inputNotes.text = nil
        
        if let member = member {
            self.title = "Edit member"
            self.navigationItem.rightBarButtonItem = nil
            
            if let photo = member.photo {
                photoView.image = photo
                photoView.imageUrl = nil
            }
            if let url = member.photoUrl {
                photoView.imageUrl = url
                photoView.layer.cornerRadius = self.photoView.frame.size.width / 2
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
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Update", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissKeyboard))
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

    @IBAction func didClickSwitch(_ sender: UISwitch?) {
        let status: MemberStatus = switchInactive.isOn ? .inactive : .active
        member?.status = status.rawValue
    }

    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        self.view.endEditing(true)
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonPhoto)
    }

    @IBAction func didClickSave(_ sender: AnyObject?) {
        saveMember()
    }
    
    fileprivate func saveMember() {
        let email = self.inputEmail.text
        let name = self.inputName.text
        let notes = inputNotes.text
        let status: MemberStatus = switchInactive.isOn ? .inactive : .active
        
        if let email = email, !email.isEmpty, !email.isValidEmail() {
            // only check for validity if email was entered
            self.simpleAlert("Invalid email", message: "Please enter a valid email if it exists.")
            return
        }
        
        if isCreatingMember {
            OrganizationService.shared.createMember(email: email, name: name, notes: notes, status: status) { [weak self] (member, error) in
                
                if let member = member {
                    var params: [String:Any] = ["id": member.id]
                    if let name = member.name { params["name"] = name }
                    if let email = member.email { params["email"] = email }
                    LoggingService.log(type: "MemberCreated", info: params)

                    if let photo = self?.newPhoto {
                        member.photo = photo
                        let alert = UIAlertController(title: "Uploading...", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
                        })
                        print("FirebaseImageService: uploading member photo for \(member.id)")
                        self?.present(alert, animated: true, completion: nil)
                        FirebaseImageService.uploadImage(image: photo, type: "member", uid: member.id, progressHandler: { (percent) in
                            alert.title = "Upload progress: \(Int(percent*100))%"
                        }, completion: { (url) in
                            alert.dismiss(animated: true, completion: nil)
                            if let url = url {
                                member.photoUrl = url
                                print("FirebaseImageService: uploading member photo complete with url \(url)")
                            }
                            params["source"] = "CreateMember"
                            LoggingService.log(type: "MemberPhoto", info: params)
                            self?.delegate?.didCreateMember(member)
                            self?.close()
                        })
                    } else {
                        self?.delegate?.didCreateMember(member)
                        self?.close()
                    }
                } else {
                    self?.simpleAlert("Could not create member", message: "The member info could not be saved.", completion: {
                        self?.close()
                    })
                }
            }
        } else if let member = member {
            var params: [String:Any] = ["id": member.id]
            if let name = self.member?.name { params["name"] = name }
            if let email = self.member?.email { params["email"] = email }
            params["status"] = status.rawValue
            LoggingService.log(type: "MemberUpdated", info: params)
            if let photo = newPhoto {
                member.photo = photo
                let alert = UIAlertController(title: "Uploading...", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .cancel) { (action) in
                })

                print("FirebaseImageService: uploading member photo for \(member.id)")
                present(alert, animated: true, completion: nil)
                FirebaseImageService.uploadImage(image: photo, type: "member", uid: member.id, progressHandler: { (percent) in
                    alert.title = "Upload progress: \(Int(percent*100))%"
                }, completion: { [weak self] (url) in
                    alert.dismiss(animated: true, completion: nil)
                    if let url = url {
                        member.photoUrl = url
                        print("FirebaseImageService: uploading member photo complete with url \(url)")
                    }
                    params["source"] = "UpdateMember"
                    LoggingService.log(type: "MemberPhoto", info: params)
                    self?.delegate?.didUpdateMember(member)
                    self?.close()
                })
            } else {
                self.delegate?.didUpdateMember(member)
                close()
            }
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
            if let text = textField.text, !text.isEmpty {
                member.name = text
            }
            else {
                textField.text = member.name
            }
        }
        else if textField == inputEmail {
            if let text = textField.text, !text.isEmpty {
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
    @objc func dismissKeyboard() {
        view.endEditing(true)
        
        if let member = self.member {
            member.notes = self.inputNotes.text
        }
    }
}

// MARK: Camera
extension MemberInfoViewController: CameraHelperDelegate {
    func didCancelSelection() {
        print("Did not edit image")
    }
    
    func didCancelPicker() {
        print("Did not select image")
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectPhoto(selected: UIImage?) {
        self.photoView.image = selected
        self.photoView.layer.cornerRadius = photoView.frame.size.width / 2
        self.newPhoto = selected
        dismiss(animated: true, completion: nil)
    }
}
