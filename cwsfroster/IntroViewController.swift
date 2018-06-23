//
//  IntroViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse
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
    var isParseConversion: Bool = false

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
        if PFUser.current() == nil {
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
        self.notify(.LoginSuccess, object: nil, userInfo: ["convertedFromParse": isParseConversion])
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
        PFUser.enableAutomaticUser()
        self.goToPractices()
    }
    
    func goToPractices() {
        showProgress("Loading...")
        if let userId = firAuth.currentUser?.uid {
            let ref = firRef.child("users").child(userId)
            ref.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
                guard snapshot.exists(), let dict = snapshot.value as? [String: Any] else {
                    self.goToPracticesHelper()
                    return
                }
                print("snapshot \(snapshot)")
                if let username = dict["parseUsername"] as? String, let password = self.inputPassword.text, !password.isEmpty  {
                    self.loginToParse(email: username, password: password, completion: { (success, error) in
                        print("Log in to parse: \(success) \(error)")
                        self.goToPracticesHelper()
                    })
                } else {
                    self.goToPracticesHelper()
                }
            }
        } else {
            self.goToPracticesHelper()
        }
    }
    
    fileprivate func goToPracticesHelper() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showProgress(_:)), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideProgress), object: nil)
        
        notifyForLogInSuccess()
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
        createEmailUser(email: email, parseUsername: nil)
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
        // tries firebase login.
        // 0) if firebase fails because username is not an email, try parse login then prompt for an email
        // 1) if firebase fails because of invalid password, retries
        // 2) if firebase fails because of user, tries parse login.
        // 3) if parse login is successful, creates firebase user
        // 4) if parse login is unsuccessful because of invalid password, retries
        // 5) if parse login is unsuccessful because of invalid user, creates firebase user
        enableButtons(false)
        showProgress("Logging in...")
        
        loginToFirebase(email: email, password: password) { (user, error) in
            if let error = error as? NSError {
                print("Error: \(error)")
                if error.code == 17008 {
                    // 0) not an email login. try parse
                    self.loginToParse(email: email, password: password, completion: { (success, error) in
                        if success {
                            self.isParseConversion = true
                            self.hideProgress() {
                                self.promptForNewEmail(parseUsername: email)
                            }
                        } else {
                            self.hideProgress() {
                                self.simpleAlert("Could not log in", message: "Please try again")
                                self.enableButtons(true)
                            }
                            return
                        }
                    })
                }
                else if error.code == 17009 { // 1) invalid firebase password
                    self.hideProgress() {
                        self.simpleAlert("Invalid password", message: "Please try again")
                        self.enableButtons(true)
                    }
                    return
                }
                else if error.code == 17011 { // 2) invalid firebase user
                    // invalid user. firebase error message is too wordy
                    self.loginToParse(email: email, password: password, completion: { (success, error) in
                        if let error = error as? NSError {
                            print("Error \(error)")
                            if error.code == 100 {
                                // 4) invalid parse login. user exists
                            } else {
                                // 5) no user.
                            }
                        } else {
                            // 3) parse login is successful; signup in firebase
                            self.createEmailUser(email: email, parseUsername: email)
                            return
                        }
                    })
                }
                else { // unknown error
                    self.hideProgress() {
                        self.simpleAlert("Could not login", message: "Unknown error: \(error)")
                        self.enableButtons(true)
                    }
                }
            } else {
                self.goToPractices()
                if let user = user {
                    self.createFirebaseUser(id: user.uid, username: nil)
                }
            }
        }
    }
    
    func loginToFirebase(email: String, password: String, completion:((_ user: User?, _ error: Error?) -> Void)?) {
        firAuth.signIn(withEmail: email, password: password, completion: { [weak self] (result, error) in
            if let error = error {
                completion?(nil, error)
            }
            else if let user = result?.user {
                print("LoginLogout: LoginSuccess from email")
                completion?(user, nil)
            }
        })
    }
    
    func loginToParse(email: String, password: String, completion:((_ success: Bool, _ error: Error?) -> Void)?) {
        PFUser.logInWithUsername(inBackground: email, password: password) { (user, error) in
            if let error = error {
                completion?(false, error)
            } else {
                completion?(true, nil)
            }
        }
    }
    
    func createEmailUser(email: String, parseUsername: String?) {
        guard let password = self.inputPassword.text, !password.isEmpty else {
            self.simpleAlert("Please enter your password", message: nil)
            self.hideProgress()
            return
        }
        if parseUsername == nil {
            // a parse user has already logged into parse and confirmed their password, so we do not need/have a confirmation field
            guard let confirmation = self.inputConfirmation.text, confirmation == password else {
                self.simpleAlert("Password and confirmation must match", message: nil)
                return
            }
        }

        firAuth.createUser(withEmail: email, password: password, completion: { (result, error) in
            if let error = error as NSError? {
                print("Error: \(error)")
                if error.code == 17007, let parseUsername = parseUsername {
                    // email already taken; try logging in
                    self.loginToFirebase(email: email, password: password, completion: { (user, error) in
                        if let error = error as NSError? {
                            self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
                            self.hideProgress()
                            LoggingService.shared.log(event: .createEmailUser, message: error.debugDescription, info: ["email": email, "parseUsername": parseUsername])
                        } else {
                            self.goToPractices()
                            // BOBBY TODO is this an extra?
                            if let user = user {
                                self.createFirebaseUser(id: user.uid, username: parseUsername)
                            }
                            LoggingService.shared.log(event: .createEmailUser, message: "user reused same email for new migration", info: ["email": email, "parseUsername": parseUsername])
                        }
                    })
                } else if error.code == 17006 {
                    // project not set up with email login. this should not happen anymore
                    self.hideProgress() {
                        self.simpleAlert("Could not sign up", defaultMessage: "Please contact us and let us know this error code: \(error.code)", error: nil)
                    }
                } else {
                    self.hideProgress() {
                        self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
                        LoggingService.shared.log(event: .createEmailUser, message: error.debugDescription, info: ["email": email, "parseUsername": parseUsername])
                    }
                }
                self.enableButtons(true)
            }
            else {
                print("createUser results: \(String(describing: result))")
                guard let user = result?.user else { return }
                if self.isSignup {
                    // create org
                    LoggingService.shared.log(event: .createEmailUser, message: "create email user success on signup", info: ["email": email])
                    self.hideProgress() {
                        self.promptForNewOrgName(completion: { (name) in
                            let userId = user.uid
                            let orgName = name ?? user.email ?? "unnamed"
                            self.createFirebaseUser(id: user.uid, username: parseUsername)
                            OrganizationService.shared.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
                            
                            self.goToPractices()
                        })
                    }
                } else {
                    LoggingService.shared.log(event: .createEmailUser, message: "create email user success on migration", info: ["email": email, "username": parseUsername])
                    self.goToPractices()
                    // BOBBY TODO is this extra?
                    self.createFirebaseUser(id: user.uid, username: parseUsername)
                }
            }
        })
    }

    func promptForNewEmail(parseUsername: String) {
        let alert = UIAlertController(title: "Please add an email", message: "Your account must be associated with an email. Please enter your email for logging in.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let email = textField.text, !email.isEmpty {
                self.createEmailUser(email: email, parseUsername: parseUsername)
                self.showProgress("Migrating account...")
            } else {
                print("Invalid email")
                PFUser.logOut()
                self.enableButtons(true)
                self.hideProgress()
                return
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            LoggingService.shared.log(event: .createEmailUser, message: "create email user cancelled", info: ["parseUsername": parseUsername])
            PFUser.logOut()
            self.hideProgress()
            self.enableButtons(true)
            return
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func createFirebaseUser(id: String, username: String?) {
        // TODO: does this need to be a user? can it be in the organization?
        let ref = firRef.child("users").child(id)
        var params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
        if let username = username {
            params["parseUsername"] = username
        }
        ref.updateChildValues(params)
    }
    
    func promptForNewOrgName(completion: ((String?)->Void)?) {
        let alert = UIAlertController(title: "What is your organization called?", message: "Please enter the name for your organization.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "i.e. Boston Soccer Social Club"
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let name = textField.text, !name.isEmpty {
                LoggingService.shared.log(event: .createOrganization, info: ["name": name])
                completion?(name)
            } else {
                LoggingService.shared.log(event: .createOrganization, info: nil)
                completion?(nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            LoggingService.shared.log(event: .createOrganization, info: ["skipped": true])
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

extension IntroViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Password reset
extension IntroViewController {
    @IBAction func didClickPasswordReset(_ sender: Any?) {
        guard let user = PFUser.current() else { return }
        let message: String
        if let email = user.email, email.isValidEmail() {
            message = "Sending a password reset link to \(email)"
        } else {
            message = "Please enter an email associated with your account"
        }
        let alert = UIAlertController(title: "Request password reset", message: "Please enter an email associated with your account.", preferredStyle: .alert)
        
        if user.email == nil {
            alert.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "Email"
            }
        }
        alert.addAction(UIAlertAction(title: "Reset", style: .default, handler: { (action) in
            if let email = user.email, email.isValidEmail() {
                self.resetPassword(email)
            } else if let textField = alert.textFields?[0], let email = textField.text {
                self.resetPassword(email)
            } else {
                // do nothing
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            LoggingService.shared.log(event: .passwordReset, message: nil, info: ["email": user.email, "cancelled": true])
            return
        }))
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func resetPassword(_ email: String) {
        PFUser.requestPasswordResetForEmail(inBackground: email) { [weak self] (success, error) in
            if success {
                self?.simpleAlert("Password reset sent", message: "Please check your email for password reset instructions")
                LoggingService.shared.log(event: .passwordReset, message: nil, info: ["email": email, "success": true])
            } else if let error = error as? NSError {
                if error.code == 125 {
                    self?.simpleAlert("Invalid email", message: "Please enter a valid email to send a reset link")
                } else if error.code == 205 {
                    self?.simpleAlert("Invalid user", message: "No user was found with that email. Please create a new account.")
                } else {
                    self?.simpleAlert("Error resetting password", defaultMessage: "Please create a new account", error: error)
                }
                LoggingService.shared.log(event: .passwordReset, message: nil, info: ["email": email, "success": false, "error": error])
            }
        }
    }
}
