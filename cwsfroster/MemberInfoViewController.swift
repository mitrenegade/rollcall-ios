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
//            let image = UIImage.init(data: photo)
//            buttonPhoto.setImage(image, for: .normal)
//            buttonPhoto.layer.cornerRadius = buttonPhoto.frame.size.width / 2
        }
        newPhoto = nil
        inputNotes.text = nil
        
        if let member = member {
            self.title = "Edit member"
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.title = "New member"
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
                    self.delegate?.didUpdateMember(member)
                }
            })
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func saveMember() {
        member?.saveInBackground()
        //        [ParseLog logWithTypeString:@"MemberCreated" title:nil message:nil params:nil error:nil];
    }

    @IBAction func didClickClose(_ sender: AnyObject?) {
        self.close()
    }
    
    @IBAction func didClickAddPhoto(_ sender: AnyObject?) {
        
    }

    @IBAction func didClickSwitch(_ sender: AnyObject?) {
        
    }
    
    @IBAction func didClickSave(_ sender: AnyObject?) {
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
            if text.isValidEmail() {
                self.member?.email = text
            }
        }
        if let text = inputNotes.text, text.characters.count > 0 {
            member?.notes = text
        }
        if let photo = self.newPhoto {
            // TODO: set photo
        }
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

