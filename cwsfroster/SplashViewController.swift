//
//  SplashViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import RxSwift
import RxOptional
import Firebase

class SplashViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var logo: RAImageView!
    
    @IBOutlet weak var constraintActivityIndicatorToLogo: NSLayoutConstraint!
    
    var first: Bool = true
    
    fileprivate var disposeBag = DisposeBag()
    
    var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin(_:)), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
        
        SettingsService.shared.observedSettings?.take(1).subscribe(onNext: {[weak self]_ in
            print("Settings updated")
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        activityIndicator.stopAnimating()
        labelInfo.isHidden = true
        labelInfo.text = nil

        guard AuthService.isLoggedIn else {
            goHome()
            return
        }
        
        if firAuth.currentUser != nil {
            if let org = OrganizationService.shared.current.value {
                goHome()
            } else {
                self.didLogin(nil)
            }
        } else if PFUser.current() != nil {
            // synchronize
            startMigrationProcess()
        }
    }
    
    func goHome() {
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            let segue: String
            if AuthService.isLoggedIn {
                segue = "toMain"
            } else {
                segue = "toLogin"
            }
            performSegue(withIdentifier: segue, sender: nil)
        }
    }
    
    func didLogin(_ notification: NSNotification?) {
        print("didLogin, convertedFromParse: \(notification?.userInfo?["convertedFromParse"])")
        // update firebase object
        if let userInfo = notification?.userInfo, let convertedFromParse = userInfo["convertedFromParse"] as? Bool, convertedFromParse {
            synchronizeParseOrganization()
            LoggingService.shared.log(event: .migrateSynchronizeParse, info: nil)
        } else {
            activityIndicator.startAnimating()
            labelInfo.isHidden = false
            labelInfo.text = "Loading organization"
            OrganizationService.shared.startObservingOrganization()
            OrganizationService.shared.current.asObservable().distinctUntilChanged().filterNil().subscribe(onNext: { (org) in
                if let url = org.photoUrl {
                    self.logo.imageUrl = url
                    UIView.animate(withDuration: 0.25, animations: {
                        self.logo.alpha = 1
                    }, completion: { (success) in
                        self.goHome()
                    })
                } else {
                    self.goHome()
                }
                self.disposeBag = DisposeBag() // stops listening
            }).disposed(by: disposeBag)
        }
    }
    
    func didLogout() {
        print("logged out")
        goHome()
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
    }
}

// MARK: Models - ensure that parse models are updated into core data when automatically logging in
var classNames = ["members", "practices", "attendances"]
extension SplashViewController {
    func synchronizeParseOrganization() {
        guard !OFFLINE_MODE else {
            OrganizationService.shared.startObservingOrganization()
            return
        }
        
        hideProgress()
        
        print("Calling synchronize with parse")
        classNames = ["members", "practices", "attendances"]
        activityIndicator.startAnimating()
        labelInfo.isHidden = false
        
        guard let user = PFUser.current() else {
            if AuthService.isLoggedIn {
                activityIndicator.stopAnimating()
                OrganizationService.shared.startObservingOrganization()
            }
            return
        }
        
        Analytics.setUserProperty("true", forName: "ConvertedFromParse")

        // if org does not exist, create org in firebase
        guard let orgPointer: PFObject = user.object(forKey: "organization") as? PFObject else {
            syncComplete()
            return
        }
        
        orgPointer.fetchInBackground { [weak self] (object, error) in
            guard let org = object as? Organization, let orgId = org.objectId else {
                self?.simpleAlert("Invalid organization", message: "We could not log you in or load your organization. Please try again.", completion: {
                    AuthService.logout()
                    self?.didLogout()
                })
                return
            }
            Organization.current = org

            if let imageFile: PFFile = org.object(forKey: "logoData") as? PFFile {
                imageFile.getDataInBackground(block: { (data, error) in
                    DispatchQueue.main.async {
                        if let data = data, let image = UIImage(data: data) {
                            self?.logo.image = image
                            self?.constraintActivityIndicatorToLogo.priority = UILayoutPriorityDefaultHigh
                            UIView.animate(withDuration: 0.25, animations: {
                                self?.logo.alpha = 0 // 1
                            })
                        }
                        self?.syncParseObjects()
                        print("Synchronize: logo complete")
                    }
                })
            } else {
                self?.syncParseObjects()
                self?.logo.alpha = 0;
                self?.logo.image = nil
                self?.constraintActivityIndicatorToLogo.priority = UILayoutPriorityDefaultLow
            }
        }
    }
    
    func syncParseObjects() {
        labelInfo.text = "Loading..."
        let group = DispatchGroup()
        
        group.enter()
        Organization.queryForMembers(completion: { [weak self] (results, error) in
            self?.labelInfo.text = "Loaded members"
            if let members = results {
                Organization.current?.members = members
                
                for member: Member in members {
                    guard let id = member.objectId else { continue }
                    guard let orgId = Organization.current?.objectId else { continue }

                    let ref = firRef.child("members").child(id)
                    var params: [String: Any] = ["organization": orgId, "createdAt": Date().timeIntervalSince1970]
                    if let name = member.name {
                        params["name"] = name
                    }
                    if let email = member.email {
                        params["email"] = email
                    }
                    if let notes = member.notes {
                        params["notes"] = notes
                    }
                    if let photo = member.photo {
                        photo.getDataInBackground(block: { (data, error) in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    // upload must happen on main queue
                                    FirebaseImageService.uploadImage(image: image, type: "member", uid: id, completion: { (url) in
                                        if let url = url {
                                            let asyncRef = firRef.child("members").child(id)
                                            asyncRef.updateChildValues(["photoUrl":url])
                                        }
                                    })
                                }
                            }
                        })
                    }

                    if let status = member.status {
                        switch status.intValue {
                        case MemberStatus.Active.rawValue:
                            params["status"] = "active"
                        case MemberStatus.Inactive.rawValue:
                            params["status"] = "inactive"
                        default:
                            params["status"] = "active"
                        }
                    }
                    ref.updateChildValues(params)
                    
                    let orgMemberRef = firRef.child("organizationMembers").child(orgId)
                    var memberParams: [String: Any] = [:]
                    if let status = member.status {
                        switch status.intValue {
                        case MemberStatus.Active.rawValue:
                            memberParams[id] = "active"
                        case MemberStatus.Inactive.rawValue:
                            memberParams[id] = "inactive"
                        default:
                            memberParams[id] = "active"
                        }
                    }
                    orgMemberRef.updateChildValues(memberParams)
                }
                classNames.remove(at: classNames.index(of: "members")!)
            }
            print("Synchronize: members complete")
            group.leave()
        })

        group.enter()
        Organization.queryForPractices(completion: { [weak self] (results, error) in
            self?.labelInfo.text = "Loaded practices"
            if let practices = results {
                Organization.current?.practices = practices
                
                for practice: Practice in practices {
                    guard let id = practice.objectId else { continue }
                    let ref = firRef.child("events").child(id)
                    var params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
                    if let title = practice.title {
                        params["title"] = title
                    }
                    if let date = practice.date {
                        params["date"] = date.timeIntervalSince1970
                    }
                    if let notes = practice.notes {
                        params["notes"] = notes
                    }
                    if let details = practice.details {
                        params["details"] = details
                    }
                    if let orgId = Organization.current?.objectId {
                        params["organization"] = orgId
                    }
                    ref.updateChildValues(params)
                }
                classNames.remove(at: classNames.index(of: "practices")!)
            }
            print("Synchronize: events complete")
            group.leave()
        })

        group.enter()
        Organization.queryForAttendances(completion: { [weak self] (results, error) in
            self?.labelInfo.text = "Loaded attendances"
            if let attendances = results {
                Organization.current?.attendances = attendances
                for attendance: Attendance in attendances {
                    guard let eventId = attendance.practice?.objectId else { continue }
                    guard let memberId = attendance.member?.objectId else { continue }
                    guard let attended = attendance.attended?.boolValue else { continue }

                    let ref = firRef.child("events").child(eventId).child("attendees")
                    ref.updateChildValues([memberId: attended])
                }
                classNames.remove(at: classNames.index(of: "attendances")!)
            }
            print("Synchronize: attendances complete")
            group.leave()
        })
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.syncComplete()
        }
        group.notify(queue: DispatchQueue.main, work: workItem)
    }
    
    func syncComplete() {
        activityIndicator.stopAnimating()
        labelInfo.isHidden = true
        labelInfo.text = nil

        // only create organization for a migration after all other objects have been migrated
        guard let userId = firAuth.currentUser?.uid else { return }
        let orgId = Organization.current?.objectId ?? FirebaseAPIService.uniqueId()
        
        // make sure Firebase Organization exists
        let org: Organization? = Organization.current
        OrganizationService.shared.createOrUpdateOrganization(orgId: orgId, ownerId: userId, name: org?.name ?? "My Organization \(orgId)", leftPowerUserFeedback: org?.leftPowerUserFeedback?.boolValue ?? false)

        OrganizationService.shared.startObservingOrganization()
        OrganizationService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { (org) in
            self.goHome()
        }).disposed(by: disposeBag)
        
        // save image to firebase
        if let imageFile: PFFile = Organization.current?.object(forKey: "logoData") as? PFFile {
            imageFile.getDataInBackground(block: { (data, error) in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        // upload must happen on main queue
                        FirebaseImageService.uploadImage(image: image, type: "organization", uid: orgId, completion: { (url) in
                            if let url = url, let currentOrg = OrganizationService.shared.current.value {
                                currentOrg.photoUrl = url
                            }
                        })
                    }
                }
            })
        }
    }
}

extension SplashViewController {
    func startMigrationProcess() {
        guard let username = PFUser.current()?.username else {
            // this should never happen
            LoggingService.shared.log(event: .migrationFailed, info: ["reason": "no parse username"])
            simpleAlert("Login failed", message: "Please try logging in again")
            PFUser.logOut()
            return
        }
        if username.isValidEmail() {
            promptForPassword(email: username, password: nil, parseUsername: username)
        } else {
            promptForNewEmail(parseUsername: username)
        }
    }
    
    // STEP 1: prompt for an email
    func promptForNewEmail(parseUsername: String) {
        let alert = UIAlertController(title: "Please add an email", message: "Your account must be associated with an email. Please enter your email for logging in.", preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            if let textField = alert.textFields?[0], let email = textField.text, !email.isEmpty, email.isValidEmail() {
                self.promptForPassword(email: email, password: nil, parseUsername: parseUsername)
            } else {
                self.promptForNewEmail(parseUsername: parseUsername)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            LoggingService.shared.log(event: .createEmailUser, message: "create email user cancelled", info: ["parseLoggedIn": true, "parseUsername": parseUsername])
            PFUser.logOut()
            self.hideProgress()
            self.goHome()
            return
        }))
        present(alert, animated: true, completion: nil)
    }

    // Step 2: prompt for password
    func promptForPassword(email: String, password: String?, parseUsername: String) {
        let isConfirmation: Bool = password != nil
        let title = isConfirmation ? "Confirm password" : "Please update your password"
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = isConfirmation ? "Enter the same password again" : "Enter a new password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Next", style: .default, handler: { (action) in
            guard let textField = alert.textFields?[0], let text = textField.text, !text.isEmpty else {
                let message = isConfirmation ? "Confirmation must not be empty" : "Password must not be empty"
                self.simpleAlert("Please try again", message: message, completion: {
                    self.promptForPassword(email: email, password: nil, parseUsername: parseUsername)
                })
                return
            }
            if !isConfirmation {
                self.promptForPassword(email: email, password: text, parseUsername: parseUsername)
            } else {
                if let password = password, password == text {
                    self.createEmailUser(email: email, password: password, parseUsername: parseUsername)
                } else {
                    self.simpleAlert("Please try again", message: "Password and confirmation do not match", completion: {
                        self.promptForPassword(email: email, password: nil, parseUsername: parseUsername)
                    })
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            LoggingService.shared.log(event: .createEmailUser, message: "password entry cancelled", info: ["parseLoggedIn": true, "parseUsername": parseUsername, "email": email])
            self.promptForNewEmail(parseUsername: parseUsername)
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func createEmailUser(email: String, password: String, parseUsername: String) {
        firAuth.createUser(withEmail: email, password: password, completion: { (result, error) in
            if let error = error as NSError? {
                print("Error: \(error)")
                if error.code == 17007 {
                    // email already taken; try logging in
                    self.loginToFirebase(email: email, password: password, completion: { (user, error) in
                        if let error = error as NSError? {
                            if error.code == 17009 {
                                // The password is invalid or the user does not have a password - account already in use
                                self.simpleAlert("Could not sign in", message: "The email you chose is already in use. Please check your password or try a different email.", completion: {
                                    self.promptForNewEmail(parseUsername: parseUsername)
                                })
                            } else {
                                self.simpleAlert("Could not sign in", defaultMessage: nil, error: error, completion: {
                                    self.startMigrationProcess()
                                })
                            }
                            self.hideProgress()
                            LoggingService.shared.log(event: .createEmailUser, message: "logged in migration failed", info: ["parseLoggedIn": true, "email": email, "parseUsername": parseUsername, "error": error.localizedDescription, "errorCode": error.code])
                        } else {
                            self.synchronizeParseOrganization()
                            LoggingService.shared.log(event: .createEmailUser, message: "user reused same email for logged in migration", info: ["parseLoggedIn": true, "email": email, "parseUsername": parseUsername])
                        }
                    })
                } else if error.code == 17006 {
                    // project not set up with email login. this should not happen anymore
                    self.hideProgress() {
                        self.simpleAlert("Could not sign up", defaultMessage: "Please contact us and let us know this error code: \(error.code)", error: nil)
                    }
                } else {
                    self.hideProgress() {
                        self.simpleAlert("Could not sign up", defaultMessage: nil, error: error, completion: {
                            LoggingService.shared.log(event: .createEmailUser, message: "logged in migration failed", info: ["parseLoggedIn": true, "email": email, "parseUsername": parseUsername, "error": error.localizedDescription, "errorCode": error.code])
                            if error.code == 17026 {
                                // password is too short - retry from password flow
                                self.promptForPassword(email: email, password: nil, parseUsername: parseUsername)
                            } else {
                                // retry whole migration process
                                self.startMigrationProcess()
                            }
                        })
                    }
                }
            }
            else {
                print("createUser results: \(String(describing: result))")
                guard let user = result?.user else { return }
                LoggingService.shared.log(event: .createEmailUser, message: "create email user success on logged in migration", info: ["parseLoggedIn": true, "email": email, "username": parseUsername])
                self.synchronizeParseOrganization()
            }
        })
    }
    
    fileprivate func loginToFirebase(email: String, password: String, completion:((_ user: User?, _ error: Error?) -> Void)?) {
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
}

// MARK: - Progress
extension SplashViewController {
    func showProgress(_ title: String?) {
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

