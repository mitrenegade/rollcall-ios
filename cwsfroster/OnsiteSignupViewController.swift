//
//  OnsiteSignupViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 2/11/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RACameraHelper
import Balizinha

class OnsiteSignupViewController: UIViewController {
    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputAbout: UITextField!
    weak var currentInput: UITextField?

    @IBOutlet weak var labelAttendanceCount: UILabel!
    @IBOutlet weak var labelWelcome: UILabel!
    
    @IBOutlet weak var buttonPhoto: UIButton!
    var addedPhoto: UIImage?
    var addedAttendees: [FirebaseMember] = []
    @IBOutlet weak var buttonSave: UIButton!
    
    var practice: FirebaseEvent? {
        didSet {
            if let event = practice {
                attendanceService = AttendanceService(event: event)
            } else {
                attendanceService = nil
            }
        }
    }
    let cameraHelper = CameraHelper()

    private var attendanceService: AttendanceService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem = button
        
        if let details = practice?.details, !details.isEmpty {
            title = details
        }
        labelWelcome.alpha = 0
        
        setupKeyboardDoneButtonView()
        cameraHelper.delegate = self
    }
    
    @objc func close() {
        navigationController?.popViewController(animated: true)
    }
    
    func setupKeyboardDoneButtonView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Next", style: .done, target: self, action: #selector(dismissKeyboard))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        keyboardDoneButtonView.setItems([flex, saveButton], animated: true)
        
        inputName.inputAccessoryView = keyboardDoneButtonView
        inputEmail.inputAccessoryView = keyboardDoneButtonView
        inputAbout.inputAccessoryView = keyboardDoneButtonView
    }
    
    @IBAction func didClickSignup(_ sender: AnyObject?) {
        guard let name = inputName.text, !name.isEmpty else {
            self.simpleAlert("Please enter a name", message: nil)
            return
        }
        
        // only check email if it was entered - not required
        if let email = inputEmail.text, !email.isEmpty {
            guard email.isValidEmail() else {
                self.simpleAlert("Please enter a valid email", message: nil)
                return
            }
        }
        
        self.buttonSave.isEnabled = false
        
        OrganizationService.shared.createMember(email: inputEmail.text, name: name, notes: inputAbout.text, status: .active) { [weak self] (member, error) in
            
            if let member = member {
                if let photo = self?.addedPhoto {
                    member.photo = photo
                    print("FirebaseImageService: uploading member photo for \(member.id)")
                    FirebaseImageService.uploadImage(image: photo,
                                                     type: FirebaseImageService.RollCallImageType.member,
                                                     uid: member.id,
                                                     progressHandler: { (percent) in
                        print("Upload progress: \(Int(percent*100))%")
                    }, completion: { (url) in
//                        alert.dismiss(animated: true, completion: nil)
                        if let url = url {
                            member.photoUrl = url
                            LoggingService.log(type: "MemberPhoto", info: ["id": member.id, "source": "Onsite"])
                            print("FirebaseImageService: uploading member photo complete with url \(url)")
                        }
                    })
                }

                self?.notify("member:created", object: nil, userInfo: nil)
                LoggingService.log(type: "OnsiteSignup", info: ["id": member.id, "photo": self?.addedPhoto != nil])
                
                // add attendance
                if self?.practice != nil {
                    self?.attendanceService?.createOrUpdateAttendance(for: member, status: .signedUp, completion: nil)
                }

                // enable button and reset form
                self?.buttonSave.isEnabled = true
                self?.addedAttendees.insert(member, at: 0)
                if let count = self?.addedAttendees.count {
                    self?.labelAttendanceCount.text = "New attendees: \(count)"
                }
                
                self?.labelWelcome.alpha = 1
                self?.labelWelcome.text = "Welcome \(member.name ?? "")"
                
                UIView.animate(withDuration: 0.25, delay: 2, options: .curveLinear, animations: {
                    self?.labelWelcome.alpha = 0
                }, completion: nil)
                
                self?.reset()
            } else if error != nil {
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
        self.buttonSave.isEnabled = true

        inputName.becomeFirstResponder()
    }
}

extension OnsiteSignupViewController: UITextFieldDelegate {
    @objc func dismissKeyboard() {
        currentInput?.resignFirstResponder()
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        currentInput = textField
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == inputName {
            inputEmail.becomeFirstResponder()
        }
        else if textField == inputEmail {
            inputAbout.becomeFirstResponder()
        }
        
        textField.resignFirstResponder()
    }
    
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: Camera
extension OnsiteSignupViewController: CameraHelperDelegate {
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        view.endEditing(true)
        cameraHelper.takeOrSelectPhoto(from: self, fromView: buttonPhoto)
    }
    
    func didCancelSelection() {
        print("Did not edit image")
    }
    
    func didCancelPicker() {
        print("Did not select image")
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectPhoto(selected: UIImage?) {
        buttonPhoto.setImage(selected, for: .normal)
        buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        addedPhoto = selected
        dismiss(animated: true, completion: nil)
    }
}
