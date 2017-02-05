//
//  PracticeEditViewController+Swift.swift
//  rollcall
//
//  Created by Bobby Ren on 2/5/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse
import UIKit

extension PracticeEditViewController {
 
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.practice == nil {
            constraintButtonAttendeesHeight.constant = 0
        }
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
    
    func configureForPractice() {
        if self.isNewPractice {
            self.title = "New event";
            self.practice = Practice()
            self.inputDate.text = self.title(for: Date())
            practice.title = self.inputDate.text
            
            self.viewEmail.isHidden = true
            self.buttonDrawing.isHidden = true
            self.buttonAttendees.isHidden = true
            self.inputNotes.text = nil
        }
        else {
            self.title = "Edit event"
            self.inputDate.text = self.practice.title
            self.inputDetails.text = self.practice.details
            self.inputNotes.text = self.practice.notes
            
            self.navigationItem.rightBarButtonItem = nil
        }
        originalDescription = inputDetails.text;

    }
}

// MARK: Navigation
extension PracticeEditViewController {
    @IBAction func didClickClose(_ sender: AnyObject?) {
        if !self.isNewPractice {
            self.view.endEditing(true)
            self.practice.saveInBackground(block: { (success, error) in
                self.delegate?.didEditPractice()
                self.navigationController?.dismiss(animated: true, completion: {
                })
            })
        }
        else {
            // do not save new practice
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didClickNext(_ sender: AnyObject?) {
        self.goToAttendees()
        /*
        -(IBAction)didClickSave:(id)sender {
            [self saveWithCompletion:^(BOOL success) {
                if (success) {
                self.navigationItem.leftBarButtonItem.title = @"Close";
                if (!didShowRater) {
                if (![rater showRatingsIfConditionsMetFromView:self.view forced:NO]) {
                [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
                didShowRater = YES;
                }
                else {
                [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
                }
                }];
        }
        */
    }
    
    func goToAttendees() {
        self.performSegue(withIdentifier: "ToEditAttendees", sender: nil)
    }
}

// Notes
extension PracticeEditViewController: UITextViewDelegate {
    public func textViewDidEndEditing(_ textView: UITextView) {
        self.practice.notes = self.inputNotes.text
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)

        if !self.isNewPractice {
            self.practice.saveEventually()
        }
        ParseLog.log(typeString: "NotesEntered", title: nil, message: nil, params: ["for": "practice"], error: nil)
    }
    
    // MARK: - keyboard notifications
    func keyboardWillShow(_ n: Notification) {
        let size = (n.userInfo![UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue.size
        
        // these values come from the position/offsets of the current textfields
        // offsets bring the top of the email field to the top of the screen
//        self.constraintBottomOffset.constant = size.height
//        self.constraintTopOffset.constant = -size.height
        self.view.layoutIfNeeded()
    }
    
    func keyboardWillHide(_ n: Notification) {
//        self.constraintBottomOffset.constant = 0 // by default, from iboutlet settings
//        self.constraintTopOffset.constant = 0
        self.view.layoutIfNeeded()
    }
    
}

// MARK: UITextFieldDelegate
extension PracticeEditViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == inputDate {
            lastInputDate = textField.text
            if currentRow == -1 {
                currentRow = FUTURE_DAYS - 1
                if let pickerView = textField.inputView as? UIPickerView {
                    pickerView.selectRow(Int(currentRow), inComponent: 0, animated: true)
                    self.pickerView(pickerView, didSelectRow: Int(currentRow), inComponent: 0)
                }
            }
        }            
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == inputTo {
            if let string = textField.text, string.characters.count > 0 {
                buttonEmail.isEnabled = true
                buttonEmail.alpha = 1
            }
            else {
                buttonEmail.isEnabled = false
                buttonEmail.alpha = 0.5
            }
            
            emailTo = textField.text;
        }
        else if textField == inputDate {
            self.practice.title = textField.text
        }
        else if textField == inputDetails {
            self.practice.details = textField.text
        }
        
        if !self.isNewPractice {
            self.practice.saveEventually()
        }
        
        textField.resignFirstResponder()
        
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
