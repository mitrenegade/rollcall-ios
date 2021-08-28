//
//  IntroViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Firebase

class IntroViewController: UIViewController {
    @IBOutlet weak var inputLogin: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    @IBOutlet weak var inputConfirmation: UITextField!
    
    @IBOutlet weak var buttonLoginSignup: UIButton!
    @IBOutlet weak var buttonSwitchMode: UIButton!

    @IBOutlet weak var constraintConfirmationHeight: NSLayoutConstraint!
    
    var alert: UIAlertController?

    var isSignup: Bool = false
    var isFailed: Bool = false

    @IBOutlet weak var tutorialView: TutorialScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refresh()
        enableButtons(true)
    }
    
    func refresh() {
        constraintConfirmationHeight.constant = isSignup ? 40 : 0
        inputPassword.text = nil
        inputConfirmation.text = nil
        inputLogin.superview?.layer.borderWidth = 1
        inputLogin.superview?.layer.borderColor = UIColor.lightGray.cgColor
        inputPassword.superview?.layer.borderWidth = 1
        inputPassword.superview?.layer.borderColor = UIColor.lightGray.cgColor
        inputConfirmation.superview?.layer.borderWidth = 1
        inputConfirmation.superview?.layer.borderColor = UIColor.lightGray.cgColor

        inputLogin.alpha = 1
        inputPassword.alpha = 1
        
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: 0.25, animations: {
            let title = self.isSignup ? "Sign up" : "Log in"
            self.buttonLoginSignup.setTitle(title, for: .normal)
            let title2 = self.isSignup ? "Back to login" : "New user?"
            self.buttonSwitchMode.setTitle(title2, for: .normal)
            
            self.view.layoutIfNeeded()
        })
    }
    
    func loadTutorial() {
        tutorialView.setTutorialPages(["IntroTutorial0", "IntroTutorial1", "IntroTutorial2", "IntroTutorial3"])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !UserService.shared.isLoggedIn {
            loadTutorial()
        }
        
        promptForUpgradeIfNeeded()
    }
    
    func enableButtons(_ enabled: Bool) {
        buttonLoginSignup.alpha = enabled ? 1 : 0.5
        buttonSwitchMode.alpha = enabled ? 1 : 0.5
        buttonLoginSignup.isEnabled = enabled
        buttonSwitchMode.isEnabled = enabled
    }
    
    func notifyForLogInSuccess() {
        self.notify(.LoginSuccess, object: nil, userInfo: nil)
    }
    
    @IBAction func didClickButton(_ sender: AnyObject?) {
        if sender as? UIButton == self.buttonLoginSignup {
            if self.isSignup {
                self.signup()
            }
            else {
                if OFFLINE_MODE {
                    self.offlineLogin()
                }
                else {
                    self.tryFirebaseLogin()
                }
            }
        }
        else {
            self.isSignup = !isSignup
            self.refresh()
        }
    }
    
    func offlineLogin() {
        self.goToPractices()
    }

    func goToPractices() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showProgress(_:)), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideProgress), object: nil)
        
        hideProgress {
            self.notifyForLogInSuccess()
        }
    }
}

// Firebase migration
extension IntroViewController {
    func signup() {
        guard let email = inputLogin.text, !email.isEmpty else {
            self.simpleAlert("Please enter an email", message: nil)
            return
        }
        guard let password = inputPassword.text, !password.isEmpty else {
            print("Invalid password")
            self.simpleAlert("Please enter a password", message: nil)
            return
        }
        guard let confirmation = inputConfirmation.text, !confirmation.isEmpty, confirmation == inputPassword.text else {
            self.simpleAlert("Password does not match", message: nil)
            print("Invalid password")
            return
        }
        showProgress("Creating account...")
        createEmailUser(email: email)
    }
    
    func tryFirebaseLogin() {
        guard let email = inputLogin.text, !email.isEmpty else {
            print("Invalid email")
            return
        }
        
        guard let password = inputPassword.text, !password.isEmpty else {
            print("Invalid password")
            return
        }
        enableButtons(false)
        showProgress("Logging in...")
        firAuth.signIn(withEmail: email, password: password, completion: { (result, error) in
            if let error = error as NSError? {
                print("Error: \(error)")
                if error.code == 17011 {
                    // invalid user. firebase error message is too wordy
                    self.hideProgress() {
                        self.simpleAlert("Could not login", message: "Please try again")
                        self.enableButtons(true)
                    }
                } else if error.code == 17008 { // not an email address
                    self.hideProgress() {
                        self.simpleAlert("Could not login", message: "Login must be an email address.")
                        self.enableButtons(true)
                    }
                } else { // unknown error
                    self.hideProgress() {
                        self.simpleAlert("Could not login", defaultMessage: "Unknown error", error: error)
                        self.enableButtons(true)
                    }
                }
            } else if let user = result?.user {
                self.goToPractices()
                UserService.shared.createOrUpdateFirebaseUser(id: user.uid)
            } else {
                self.simpleAlert("Unknown login error", message: "No user was found")
                UserService.shared.logout()
            }
        })
    }
    
    func createEmailUser(email: String) {
        guard let password = self.inputPassword.text, !password.isEmpty else {
            self.simpleAlert("Please enter your password", message: nil)
            self.hideProgress()
            return
        }
        guard let confirmation = self.inputConfirmation.text, confirmation == password else {
            self.simpleAlert("Password and confirmation must match", message: nil)
            return
        }

        firAuth.createUser(withEmail: email, password: password, completion: { (result, error) in
            if let error = error as NSError? {
                print("Error: \(error)")
                if error.code == 17007 {
                    // email already taken
                    self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
                    self.hideProgress()
                    LoggingService.log(event: .createEmailUser, message: "create user failed", info: ["email": email], error: error)
                } else {
                    var message: String?
                    var displayError: NSError?
                    if error.code == 17006 {
                        // project not set up with email login. this should not happen anymore
                        message = "Please contact us and let us know this error code: \(error.code)"
                        displayError = nil
                    } else if error.code == 17007 { // email already taken
                        message = nil
                        displayError = error
                    } else if error.code == 17008 {
                        message = "Please enter a valid email address."
                        displayError = nil
                    }
                    self.hideProgress() {
                        self.simpleAlert("Could not sign up", defaultMessage: message, error: displayError)
                        LoggingService.log(event: .createEmailUser, message: "other signup error", info: ["email": email], error: error)
                    }
                }
                self.enableButtons(true)
            }
            else if let user = result?.user {
                print("createUser results: \(String(describing: user))")
                if self.isSignup {
                    // create org
                    LoggingService.log(event: .createEmailUser, message: "create email user success on signup", info: ["email": email])
                    self.hideProgress() {
                        self.promptForNewOrgName(completion: { (name) in
                            let userId = user.uid
                            let orgName = name ?? user.email ?? "unnamed"
                            UserService.shared.createFirebaseUser(id: user.uid)
                            OrganizationService.shared.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
                            
                            self.goToPractices()
                        })
                    }
                } else {
                    LoggingService.log(event: .createEmailUser, message: "create email user success on migration", info: ["email": email])
                    self.goToPractices()
                    UserService.shared.createFirebaseUser(id: user.uid)
                }
            }
        })
    }

    func promptForNewOrgName(completion: ((String?)->Void)?) {
        let alert = UIAlertController(title: "What is your organization called?", message: "Please enter the name for your organization.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "i.e. Boston Soccer Social Club"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let name = textField.text, !name.isEmpty {
                LoggingService.log(event: .createOrganization, info: ["name": name])
                completion?(name)
            } else {
                LoggingService.log(event: .createOrganization, info: nil)
                completion?(nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            LoggingService.log(event: .createOrganization, info: ["skipped": true])
            completion?(nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension IntroViewController {
    func promptForUpgradeIfNeeded() {
        UpgradeService().promptForUpgradeIfNeeded(from: self)
    }
}

// MARK: - Progress
extension IntroViewController {
    @objc func showProgress(_ title: String?) {
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
    
    @objc func hideProgress(_ completion:(()->Void)? = nil) {
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

extension IntroViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

