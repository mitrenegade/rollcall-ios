//
//  EventEditViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 8/21/21.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

fileprivate let FUTURE_DAYS = 14

protocol PracticeEditDelegate: class {

    func didCreatePractice()
    func didEditPractice()

}

class EventEditViewController: UIViewController {

    var dateForDateString: [String: Date] = [:]
    private lazy var datesForPicker: [String] = {
        generatePickerDates()
    }()
    var drawn: [Bool] = []

    var practice: FirebaseEvent?
    private var createPracticeInfo = [String: Any]()

    weak var delegate: PracticeEditDelegate?

    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var inputDate: UITextField!
    @IBOutlet var inputDetails: UITextField!
    @IBOutlet var inputNotes: UITextView!

    @IBOutlet var buttonAttendees: UIButton!
    @IBOutlet var constraintButtonAttendeesHeight: NSLayoutConstraint!
    @IBOutlet var constraintButtonEmailHeight: NSLayoutConstraint!

    var originalDescription: String?

    @IBOutlet var buttonEmail: UIButton!
    @IBOutlet var buttonDrawing: UIButton!

    private var currentRow: Int = -1
    var lastInputDate: String?
    var emailFrom: String?
    var emailTo: String?

    @IBOutlet var activityOverlay: UIView!

    @IBOutlet var viewInfo: UIView!

    private lazy var pickerView: UIPickerView = {
        let view = UIPickerView()
        view.delegate = self
        view.dataSource = self
        return view
    }()

    private lazy var pickerKeyboardDoneButtonView: UIToolbar = {
        let view = UIToolbar()
        view.barStyle = .black
        view.isTranslucent = true
        view.sizeToFit()

        let button1 = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""),
                                      style: .done,
                                      target: self,
                                      action: #selector(cancelSelectDate))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let button2 = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""),
                                      style: .done,
                                      target: self,
                                      action: #selector(selectDate))
        view.setItems([button1, flex, button2], animated: false)
        view.tintColor = .white

        return view
    }()

    private lazy var detailsKeyboardDoneButtonView: UIToolbar = {
        let view = UIToolbar()
        view.barStyle = .black
        view.isTranslucent = true
        view.sizeToFit()

        let button1 = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""),
                                      style: .done,
                                      target: self,
                                      action: #selector(dismissKeyboard))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let button2 = UIBarButtonItem(title: NSLocalizedString("Next", comment: ""),
                                      style: .done,
                                      target: self,
                                      action: #selector(saveDetails))
        view.setItems([button1, flex, button2], animated: false)
        view.tintColor = .white

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        inputDate.inputView = pickerView
        inputDate.inputAccessoryView = pickerKeyboardDoneButtonView
        inputDetails.inputAccessoryView = detailsKeyboardDoneButtonView

        setupTextView()
        configureForPractice()

        setupPicker()

        emailTo = UserDefaults.standard.object(forKey: "email:to") as? String
    }

    private func setupPicker() {
        let defaultTitle = practice?.title ?? title(for: Date())

        for i in 0 ..< datesForPicker.count { // todo: map
            if defaultTitle == datesForPicker[i] {
                currentRow = i
                break
            }

            let selectedDate = dateOnly(dateForDateString[datesForPicker[i]] ?? Date()) // TODO: compactMap
            let practiceDate = practice?.dateOnly()
            if selectedDate == practiceDate {
                currentRow = i
                break
            }
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.practice == nil {
            constraintButtonAttendeesHeight.constant = 0
            constraintButtonEmailHeight.constant = 0
        }
    }
    
    @objc func setupTextView() {
        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.black
        keyboardDoneButtonView.tintColor = UIColor.white
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let saveButton: UIBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissKeyboard))
        keyboardDoneButtonView.setItems([flex, saveButton], animated: true)
        self.inputNotes.inputAccessoryView = keyboardDoneButtonView
    }
    
    private func configureForPractice() {
        if practice == nil {
            self.title = "New event";
            self.constraintButtonEmailHeight.constant = 0
            self.buttonDrawing.isHidden = true
            self.buttonAttendees.isHidden = true
            self.inputNotes.text = nil
            self.navigationItem.leftBarButtonItem?.title = "Cancel"
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }
        else {
            self.title = "Edit event"
            self.inputDate.text = self.practice?.title
            self.inputDetails.text = self.practice?.details
            self.inputNotes.text = self.practice?.notes
            
            self.navigationItem.rightBarButtonItem = nil
        }
        originalDescription = inputDetails.text;
    }
    
    fileprivate func createPractice(_ completion: @escaping ((FirebaseEvent)->Void)) {
        guard let name = createPracticeInfo["title"] as? String else { return }
        guard let date = createPracticeInfo["date"] as? Date else { return }
        guard let orgId = OrganizationService.shared.currentOrganizationId else { return }
        let details = createPracticeInfo["details"] as? String
        let notes = createPracticeInfo["notes"] as? String
        EventService.shared.createEvent(name, date: date, notes: notes, details: details, organization: orgId) { [weak self] (event, error) in
            if let event = event {
                LoggingService.log(type: "PracticeCreated", info: ["id":event.id])
                self?.delegate?.didCreatePractice()
                completion(event)
            } else {
                print("Create practice error \(error.debugDescription)")
            }
        }
    }
}

// MARK: Navigation
extension EventEditViewController {
    @IBAction func didClickClose(_ sender: AnyObject?) {
        if practice != nil {
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
        view.endEditing(true)
        if practice != nil {
            goToAttendees(for: nil)
        } else {
            createPractice { [weak self] newPractice in
                self?.goToAttendees(for: newPractice)
            }
        }
    }
    
    // MARK: - Attendees
    @IBAction func didClickAttendees(_ sender: Any?) {
        didClickNext(nil)
    }
    
    // MARK: - Onsite signup
    @IBAction func didClickOnsiteSignup(_ sender: Any?) {
        if practice != nil {
            goToOnsiteSignup()
        } else {
            createPractice { [weak self] newPractice in
                self?.navigationItem.leftBarButtonItem?.title = "Close"
                self?.goToAttendees(for: newPractice)
            }
        }
    }
    
    private func goToAttendees(for newEvent: FirebaseEvent?) {
        let controller = AttendanceTableViewController()
        controller.delegate = delegate
        if let newEvent = newEvent {
            controller.currentPractice = newEvent
            controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil) // hide/disable back button
        } else {
            controller.currentPractice = practice
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    private func goToOnsiteSignup() {
        guard let controller = UIStoryboard(name: "Events", bundle: nil)
            .instantiateViewController(identifier: "OnsiteSignupViewController") as? OnsiteSignupViewController else {
                return
            }
        controller.practice = practice
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToRandomDrawing", let controller = segue.destination as? RandomDrawingViewController {
            if let practice = practice {
                controller.practice = practice
            }
        }
    }
}

// Notes
extension EventEditViewController: UITextViewDelegate {
    public func textViewDidEndEditing(_ textView: UITextView) {
        practice?.notes = self.inputNotes.text
        createPracticeInfo["notes"] = self.inputNotes.text
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)

        LoggingService.log(type: "NotesEntered", message: self.inputNotes.text ?? "", info: ["for": "practice"])
    }
    
    // MARK: - keyboard notifications
    func keyboardWillShow(_ n: Notification) {
        self.view.layoutIfNeeded()
    }
    
    func keyboardWillHide(_ n: Notification) {
        self.view.layoutIfNeeded()
    }
    
}


// MARK: UITextFieldDelegate
extension EventEditViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == inputDate {
            lastInputDate = textField.text
            if currentRow == -1 {
                currentRow = FUTURE_DAYS - 1
            }
            if let pickerView = textField.inputView as? UIPickerView {
                pickerView.selectRow(currentRow, inComponent: 0, animated: true)
                self.pickerView(pickerView, didSelectRow: currentRow, inComponent: 0)
            }
        }
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == inputDate {
            practice?.title = textField.text
            createPracticeInfo["title"] = textField.text
            
            if let text = inputDate.text, let date = dateForDateString[text] {
                practice?.date = date
                createPracticeInfo["date"] = date
                if let practice = practice {
                    LoggingService.log(type: "PracticeDateChanged", info: ["id": practice.id, "date": text])
                }
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            }
        }
        else if textField == inputDetails {
            practice?.details = textField.text
            createPracticeInfo["details"] = textField.text
        }
        
        textField.resignFirstResponder()
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: Email
extension EventEditViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    @IBAction func didClickEmail(_ sender: AnyObject?) {
        let alert = UIAlertController(title: "To:", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = self.emailTo
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action) in
            if let textField = alert.textFields?.first {
                self.emailTo = textField.text
                guard let email = self.emailTo, !email.isEmpty else {
                    self.simpleAlert("Invalid recipient", message: "Please enter a valid email recipient")
                    return
                }
                self.activityOverlay.isHidden = false
                
                if self.practice != nil {
                    self.composeEmail()
                } else {
                    self.createPractice { (event) in
                        self.practice = event
                        self.composeEmail()
                    }
                }
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func composeEmail() {
        guard let practice = practice else {
            simpleAlert("Could not compose email", message: "The event was not saved correctly. Please save the event first then try sending a summary again.")
            return
        }
        self.activityOverlay.isHidden = true

        UserDefaults.standard.set(self.emailTo, forKey: "email:to")
        
        let eventName = self.practice?.title ?? "practice"
        let title = "Event attendance for \(eventName)"
        let dateString = Util.simpleDateFormat(self.practice?.date ?? Date(), local: true) ?? "n/a"
        var message = "Date: \(dateString)\n"
        
        let attendees = practice.attendees
        OrganizationService.shared.members { [weak self] (members, error) in
            let attended = members.filter({ (member) -> Bool in
                attendees.contains(member.id)
            }).sorted{
                guard let n1 = $0.name?.uppercased() else { return false }
                guard let n2 = $1.name?.uppercased() else { return true }
                return n1 < n2
            }
            
            for member in attended {
                if let name = member.name {
                    message = "\(message)\n\(name) "
                }
                if let email = member.email {
                    message = "\(message)\(email)"
                }
            }
            self?.sendEmail(title: title, message: message)
        }
    }
    
    func sendEmail(title: String, message: String) {
        guard MFMailComposeViewController.canSendMail() else {
            self.simpleAlert("Cannot send email", message: "Your device is unable to send email.")
            self.activityOverlay.isHidden = true
            return
        }
        guard let emailTo = emailTo, !emailTo.isEmpty else {
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
        LoggingService.log(type: "EmailEventDetails", info: ["org": OrganizationService.shared.currentOrganizationId ?? "unknown", "event": self.practice?.id, "subject": title, "body": message])
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true) { 
            if result == .cancelled || result == .failed {
                self.simpleAlert("Attendance record cancelled", defaultMessage: "The event summary was not sent", error: error as NSError?)
            }
            else if result == .sent {
                self.simpleAlert("Attendance record sent", message: nil)
            }
        }
    }
}

extension EventEditViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        datesForPicker.count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        datesForPicker[row]
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let title = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        inputDate.text = title
        currentRow = row
    }

    // MARK: - Helpers for picker

    private func generatePickerDates() -> [String] {
        var dates = [String]()
        dateForDateString = [:]

        let futureDays = FUTURE_DAYS // allow 2 weeks into the future
        for row in 0 ..< 31 + futureDays {

            let secs = TimeInterval(-24*3600*(row-futureDays))
            let date = Date().addingTimeInterval(secs)
            if let title = self.title(for: date) {
                dates.insert(title, at: 0)
                dateForDateString[title] = date
            }
        }
        return dates
    }

    private func title(for date: Date) -> String? {
        guard let dayString = Util.weekdayString(from: date, localTimeZone: true),
              let dateString = Util.simpleDateFormat(date) else {
            return nil
        }
        return "\(dayString) \(dateString)"
    }

    @objc private func selectDate() {
        inputDate.resignFirstResponder()
        inputDetails.becomeFirstResponder()
    }

    @objc private func cancelSelectDate() {
        inputDate.text = lastInputDate
        inputDate.resignFirstResponder()
    }

    @objc private func saveDetails() {
        inputDetails.resignFirstResponder()
        inputNotes.becomeFirstResponder()
    }

    func dateOnly(_ date: Date) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(Set([.year, .month, .day]), from: date)
        return calendar.date(from: components)
    }

}
