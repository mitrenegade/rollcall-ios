//
//  IntroViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import Parse
import Firebase

// MARK: Swift notifications
extension IntroViewController {
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
                            self.promptForNewEmail(parseUsername: email)
                            self.isParseConversion = true
                        } else {
                            self.simpleAlert("Could not log in", message: "Please try again")
                            self.hideProgress()
                            self.enableButtons(true)
                            return
                        }
                    })
                }
                else if error.code == 17009 { // 1) invalid firebase password
                    self.simpleAlert("Invalid password", message: "Please try again")
                    self.hideProgress()
                    self.enableButtons(true)
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
                    self.simpleAlert("Could not login", message: "Unknown error: \(error)")
                    self.hideProgress()
                    self.enableButtons(true)
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
                        } else {
                            self.goToPractices()
                            if let user = user {
                                self.createFirebaseUser(id: user.uid, username: parseUsername)
                            }
                        }
                    })
                } else if error.code == 17006 {
                    // project not set up with email login. this should not happen anymore
                    self.simpleAlert("Could not sign up", defaultMessage: "Please contact us and let us know this error code: \(error.code)", error: nil)
                    self.hideProgress()
                } else {
                    self.simpleAlert("Could not sign up", defaultMessage: nil, error: error)
                    self.hideProgress()
                }
                self.enableButtons(true)
            }
            else {
                print("createUser results: \(String(describing: result))")
                guard let user = result?.user else { return }
                if self.isSignup {
                    // create org
                    self.promptForNewOrgName(completion: { (name) in
                        let userId = user.uid
                        let orgName = name ?? user.email ?? "unnamed"
                        self.createFirebaseUser(id: user.uid, username: parseUsername)
                        OrganizationService.shared.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
                        
                        self.goToPractices()
                    })
                } else {
                    self.goToPractices()
                    self.createFirebaseUser(id: user.uid, username: nil)
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
                completion?(name)
            } else {
                completion?(nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            completion?(nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension IntroViewController {
    func promptForUpgradeIfNeeded() {
        let service = UpgradeService()
        guard service.shouldShowSoftUpgrade || service.shouldShowForceUpgrade else { return }
        
        let title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "RollCall"
        let version = SettingsService.newestVersion
        let alert = UIAlertController(title: "Upgrade available", message: "There is a newer version (\(version)) of \(title) available in the App Store.", preferredStyle: .alert)
        if let url = URL(string: APP_STORE_URL), UIApplication.shared.canOpenURL(url)
        {
            alert.addAction(UIAlertAction(title: "Open in App Store", style: .default, handler: { (action) in
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "appStore"])
                service.softUpgradeDismissed(neverShowAgain: false)
            }))
        }
        if service.shouldShowSoftUpgrade {
            alert.addAction(UIAlertAction(title: "Do not show again", style: .default, handler: { (action) in
                service.softUpgradeDismissed(neverShowAgain: true)
                LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "neverShowAgain"])
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
                service.softUpgradeDismissed(neverShowAgain: false)
                LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "later"])
            }))
        }
        present(alert, animated: true)
    }
}
