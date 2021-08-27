//
//  FeedbackViewController.swift
//  Panna
//
//  Created by Bobby Ren on 9/19/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import Firebase

class FeedbackViewController: UIViewController {

    @IBOutlet weak var inputSubject: UITextField!
    @IBOutlet weak var inputEmail: UITextField!
    @IBOutlet weak var inputDetails: UITextView!

    @IBOutlet weak var constraintBottomOffset: NSLayoutConstraint!
    
    var isLeagueInquiry: Bool {
        return false
    }
    fileprivate var shouldCancelInput: Bool = false
    var alert: UIAlertController?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Feedback"
        
        if let email = UserService.shared.currentUserEmail {
            inputEmail.text = email
        }
        
        inputDetails.layer.borderWidth = 1
        inputDetails.layer.borderColor = UIColor.lightGray.cgColor
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .done, target: self, action: #selector(didClickSubmit(sender:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(close))

        // Do any additional setup after loading the view, typically from a nib.
        let keyboardNextButtonView = UIToolbar()
        keyboardNextButtonView.sizeToFit()
        keyboardNextButtonView.barStyle = UIBarStyle.black
        keyboardNextButtonView.isTranslucent = true
        keyboardNextButtonView.tintColor = UIColor.white
        let cancel: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.done, target: self, action: #selector(cancelInput))
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        keyboardNextButtonView.setItems([flex, cancel], animated: true)
        
        inputSubject.inputAccessoryView = keyboardNextButtonView
        inputDetails.inputAccessoryView = keyboardNextButtonView
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func didClickSubmit(sender: UIButton?) {
        guard let subject = inputSubject.text, !subject.isEmpty else {
            simpleAlert("Please enter a subject", message: nil)
            return
        }
        
        guard let email = inputEmail.text, email.isValidEmail() else {
            var message = "We will respond to your feedback as soon as possible."
            if isLeagueInquiry {
                message = "We will respond to your inquiry as soon as possible."
            }
            simpleAlert("Please enter a valid email", message: message)
            return
        }

        guard let userId = UserService.shared.currentUserID else { return }
        var params: [String: Any] = ["subject": subject, "userId": userId, "email": email]
        if let details = inputDetails.text, !details.isEmpty {
            params["details"] = details
        }
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        params["version"] = version
        let org = OrganizationService.shared.currentOrganizationName ?? ""
        params["organization"] = org
        let orgId = OrganizationService.shared.currentOrganizationId ?? ""
        params["organizationId"] = orgId

        cancelInput()
        
        showProgress("Submitting feedback")
        let id = FirebaseAPIService.uniqueId()
        let ref = firRef.child("feedback").child(id)
        ref.updateChildValues(params) { (error, ref) in
            print("Feedback result \(String(describing: ref)) error \(String(describing: error))")
            DispatchQueue.main.async {
                self.hideProgress({
                    if let error = error as NSError? {
                        self.simpleAlert("Feedback failed", defaultMessage: "Could not submit feedback about \"\(subject)\"", error: error)
                    } else {
                        var title = "Feedback submitted"
                        var message = "Thank you for your feedback"
                        if self.isLeagueInquiry == true {
                            title = "Inquiry submitted"
                            message = "Your question about leagues has been submitted."
                        }
                        self.simpleAlert(title, message: message, completion: {
                            self.close()
                        })
                    }
                })
            }
        }
    }
    
    @objc func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func keyboardWillShow(_ notification: Notification) {
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        constraintBottomOffset.constant = keyboardHeight
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc fileprivate func keyboardWillHide(_ notification: Notification) {
        constraintBottomOffset.constant = 20
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
}

extension FeedbackViewController: UITextFieldDelegate {
    @objc func cancelInput() {
        shouldCancelInput = true
        view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shouldCancelInput = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard !shouldCancelInput else { return }
        if textField == inputSubject {
            inputEmail.becomeFirstResponder()
        } else if textField == inputEmail {
            inputDetails.becomeFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Progress
extension FeedbackViewController {
    func showProgress(_ title: String?) {
        guard self.alert == nil else {
            self.alert?.title = title
            return
        }
        
        let alert = UIAlertController(title: title ?? "Progress", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] (action) in
            self?.alert = nil
        })
        
        present(alert, animated: true, completion: nil)
        self.alert = alert
    }
    
    func hideProgress(_ completion:(()->Void)? = nil) {
        if alert == nil {
            completion?()
        } else {
            alert?.dismiss(animated: true, completion: completion)
            alert = nil
        }
    }
    
    func updateProgress(percent: Double = 0) {
        alert?.message = "\(percent * 100)%"
    }
}
