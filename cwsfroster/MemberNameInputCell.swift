//
//  MemberNameInputCell.swift
//  rollcall
//
//  Created by Bobby Ren on 7/23/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

protocol MemberNameInputDelegate: class {
    func didAddMember(name: String)
}
class MemberNameInputCell: UITableViewCell {

    @IBOutlet weak var inputName: UITextField!
    weak var delegate: MemberNameInputDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Close", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([saveButton], animated: true)
        self.inputName.inputAccessoryView = keyboardDoneButtonView
    }
    
    func updateMember() {
        print("Add member \(String(describing: inputName.text))")
        if let name = inputName.text {
            delegate?.didAddMember(name: name)
        }
        inputName.text = nil
    }
}

// MARK: - keyboard notifications
extension MemberNameInputCell {
    @objc func dismissKeyboard() {
        endEditing(true)
    }
    
    func keyboardWillShow(_ n: Notification) {
    }
    
    func keyboardWillHide(_ n: Notification) {
    }
}

extension MemberNameInputCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        updateMember()
        return false
    }
}
