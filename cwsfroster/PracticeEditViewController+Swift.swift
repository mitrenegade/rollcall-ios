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
            practice.organization = Organization.current
            
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
        self.view.endEditing(true)
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
            if let text = inputDate.text, let date = dateForDateString[text] as? Date {
                self.practice.date = date
            }
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

// MARK: Email
extension PracticeEditViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    func didClickEmail(_ sender: AnyObject?) {
        self.inputTo.resignFirstResponder()
        guard let emailTo = self.inputTo.text, !emailTo.isEmpty else {
            self.simpleAlert("Invalid recipient", message: "Please enter a valid email recipient")
            return
        }
        
        do {
            try self.practice.save()
        }
        catch let error as NSError {
            self.simpleAlert("Event could not be saved", defaultMessage: "Could not update event before emailing out the attendance", error: error)
        }
        catch {
            self.simpleAlert("Event could not be saved", message: "Could not update event before emailing out the attendance: unknown error")
        }
        
        UserDefaults.standard.set(emailTo, forKey: "email:to")
        
        let eventName = self.practice.title ?? "practice"
        let title = "Event attendance for \(eventName)"
        let dateString = Util.simpleDateFormat(self.practice.date ?? Date(), local: true) ?? "n/a"
        var message = "Date: \(dateString)\n"
        for attendance in self.practice.attendances ?? [] {
            if let attended = attendance.attended, attended.boolValue, let member = attendance.member {
                do {
                    try member.fetchIfNeeded()
                }
                catch {
                    // do nothing
                    continue
                }
                if let name = member.name {
                    message = "\(message)\n\(name) "
                }
                if let email = member.email {
                    message = "\(message)\(email)"
                }
            }
        }
        
        self.sendEmail(title: title, message: message)
    }
    
    func sendEmail(title: String, message: String) {
        guard MFMailComposeViewController.canSendMail() else {
            self.simpleAlert("Cannot send email", message: "Your device is unable to send email.")
            return
        }
        guard let emailTo = self.inputTo.text, !emailTo.isEmpty else {
            self.simpleAlert("Invalid recipient", message: "Please enter a valid email recipient")
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setSubject(title)
        composer.setMessageBody(message, isHTML: false)
        composer.setToRecipients([emailTo])
        
        self.present(composer, animated: true, completion: nil)
        
        ParseLog.log(typeString: "EmailEventDetails", title: nil, message: nil, params: ["org": Organization.current?.objectId ?? "unknown", "event": self.practice.objectId ?? "unknown", "subject": title, "body": message], error: nil)
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true) { 
            if result == .cancelled || result == .failed {
                self.simpleAlert("Attendance record cancelled", defaultMessage: "The event summary was not sent", error: error as? NSError)
            }
            else if result == .sent {
                self.simpleAlert("Attendance record sent", message: nil)
            }
        }
    }
}
