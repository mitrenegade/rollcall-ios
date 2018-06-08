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
            constraintButtonEmailHeight.constant = 0
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
            self.constraintButtonEmailHeight.constant = 0
            self.buttonDrawing.isHidden = true
            self.buttonAttendees.isHidden = true
            self.inputNotes.text = nil
        }
        else {
            self.title = "Edit event"
            self.inputDate.text = self.practice.name
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
            self.delegate?.didEditPractice()
            self.navigationController?.dismiss(animated: true, completion: {
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

        ParseLog.log(typeString: "NotesEntered", title: nil, message: self.inputNotes.text ?? "", params: ["for": "practice"], error: nil)
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
            }
            if let pickerView = textField.inputView as? UIPickerView {
                pickerView.selectRow(Int(currentRow), inComponent: 0, animated: true)
                self.pickerView(pickerView, didSelectRow: Int(currentRow), inComponent: 0)
            }
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == inputDate {
            self.practice.name = textField.text
            if let text = inputDate.text, let date = dateForDateString[text] as? Date {
                self.practice.date = date
                ParseLog.log(typeString: "PracticeDateChanged", title: self.practice.id, message: nil, params: ["date": date], error: nil)
            }
        }
        else if textField == inputDetails {
            self.practice.details = textField.text
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
        let alert = UIAlertController(title: "To:", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = self.emailTo
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            if let textField = alert.textFields?.first {
                self.emailTo = textField.text
                self.composeEmail()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func composeEmail() {
        guard !emailTo.isEmpty else {
            self.simpleAlert("Invalid recipient", message: "Please enter a valid email recipient")
            return
        }
        self.activityOverlay.isHidden = false

        // BOBBY TODO
//        self.practice.saveInBackground { (success, error) in
//            if let error = error as? NSError {
//                self.simpleAlert("Event could not be saved", defaultMessage: "Could not update event before emailing out the attendance", error: error)
//                self.activityOverlay.isHidden = true
//                return
//            }
//            else {
                UserDefaults.standard.set(self.emailTo, forKey: "email:to")

                let eventName = self.practice.name ?? "practice"
                let title = "Event attendance for \(eventName)"
                let dateString = Util.simpleDateFormat(self.practice.date ?? Date(), local: true) ?? "n/a"
                var message = "Date: \(dateString)\n"
//                let attendances = self.practice.attendances ?? []
//                var count = attendances.count
//                for attendance in attendances {
//                    if let attended = attendance.attended, attended.boolValue, let member = attendance.member {
//                        member.fetchIfNeededInBackground(block: { (object, error) in
//                            DispatchQueue.main.async {
//                                if let member = object as? Member {
//                                    if let name = member.name {
//                                        message = "\(message)\n\(name) "
//                                    }
//                                    if let email = member.email {
//                                        message = "\(message)\(email)"
//                                    }
//                                }
//                                count -= 1
//                                if count == 0 {
//                                    self.sendEmail(title: title, message: message)
//                                }
//                            }
//                        })
//                    }
//                }
                                            self.sendEmail(title: title, message: message)
//            }
//        }
    }
    
    func sendEmail(title: String, message: String) {
        guard MFMailComposeViewController.canSendMail() else {
            self.simpleAlert("Cannot send email", message: "Your device is unable to send email.")
            self.activityOverlay.isHidden = true
            return
        }
        guard !emailTo.isEmpty else {
            self.simpleAlert("Invalid recipient", message: "Please enter a valid email recipient")
            self.activityOverlay.isHidden = true
            return
        }
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setSubject(title)
        composer.setMessageBody(message, isHTML: false)
        composer.setToRecipients([emailTo])
        
        self.present(composer, animated: true, completion: nil)
        
        self.activityOverlay.isHidden = true
        ParseLog.log(typeString: "EmailEventDetails", title: nil, message: nil, params: ["org": Organization.current?.objectId ?? "unknown", "event": self.practice.id, "subject": title, "body": message], error: nil)
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

