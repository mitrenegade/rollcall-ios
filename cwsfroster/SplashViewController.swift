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
import AsyncImageView

class SplashViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var logo: AsyncImageView!
    
    var first: Bool = true
    
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin(_:)), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        activityIndicator.stopAnimating()
        labelInfo.isHidden = true
        labelInfo.text = nil
        
        if first && AuthService.isLoggedIn {
            self.didLogin(nil)
        } else {
            goHome()
        }
        first = false
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
        guard !OFFLINE_MODE else {
            FirebaseOfflineParser.loadData()
            return
        }
        print("BOBBYTEST logged in, convertedFromParse: \(notification?.userInfo?["convertedFromParse"])")
        // update firebase object
        if let userInfo = notification?.userInfo, let convertedFromParse = userInfo["convertedFromParse"] as? Bool, convertedFromParse {
            synchronizeParseOrganization()
        } else {
            activityIndicator.startAnimating()
            OrganizationService.shared.startObservingOrganization()
            OrganizationService.shared.current.asObservable().distinctUntilChanged().filterNil().subscribe(onNext: { (org) in
                print("org \(org)")
                self.goHome()
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
//            generateOfflineModels()
            FirebaseOfflineParser.loadData()
            return
        }
        
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

        // make sure org exists
        guard let orgPointer: PFObject = user.object(forKey: "organization") as? PFObject else {
            labelInfo.text = "Creating organization"
            let org = Organization()
            org.name = user.username
            org.saveInBackground(block: { [weak self] (success, error) in
                if success {
                    user.setObject(org, forKey: "organization")
                    user.saveEventually()
                    self?.synchronizeParseOrganization()
                }
                else {
                    self?.synchronizeParseOrganization()
                }
            })
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
                do {
                    let data = try imageFile.getData()
                    if let image = UIImage(data: data) {
                        self?.logo.image = image
                        UIView.animate(withDuration: 0.25, animations: {
                            self?.logo.alpha = 1
                        })
                        self?.syncParseObjects()
                    }
                    else {
                        print("no image")
                        self?.syncParseObjects()
                    }
                }
                catch {
                    print("some error")
                    self?.syncParseObjects()
                }
            }
            else {
                self?.syncParseObjects()
                self?.logo.alpha = 0;
                self?.logo.image = nil
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
                    let ref = firRef.child("members").child(id)
                    var params: [String: Any] = ["createdAt": Date().timeIntervalSince1970]
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
//                        params["photoUrl"] = TODO
                    }
                    ref.updateChildValues(params)
                    
                    if let orgId = Organization.current?.objectId {
                        let orgMemberRef = firRef.child("organizationMembers").child(orgId)
                        var params: [String: Any] = [:]
                        if let status = member.status {
                            switch status.intValue {
                            case MemberStatus.Active.rawValue:
                                params[id] = "active"
                            case MemberStatus.Inactive.rawValue:
                                params[id] = "inactive"
                            default:
                                params[id] = "active"
                            }
                        }
                        orgMemberRef.updateChildValues(params)
                    }
                }
                classNames.remove(at: classNames.index(of: "members")!)
            }
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
        guard let org = Organization.current, let orgId = org.objectId, let userId = firAuth.currentUser?.uid else { return }
        
        // make sure Firebase Organization exists
        OrganizationService.shared.createOrUpdateOrganization(orgId: orgId, ownerId: userId, name: org.name, leftPowerUserFeedback: org.leftPowerUserFeedback?.boolValue ?? false)

        OrganizationService.shared.startObservingOrganization()
        OrganizationService.shared.current.asObservable().filterNil().take(1).subscribe(onNext: { (org) in
            self.goHome()
        }).disposed(by: disposeBag)
        
        // save image to firebase
        DispatchQueue.global().async {
            if let imageFile: PFFile = org.object(forKey: "logoData") as? PFFile {
                do {
                    let data = try imageFile.getData()
                    if let image = UIImage(data: data) {
                        FirebaseImageService.uploadImage(image: image, type: "organization", uid: orgId, completion: { (url) in
                            if let url = url, let currentOrg = OrganizationService.shared.current.value {
                                currentOrg.photoUrl = url
                            }
                        })
                    }
                } catch let error {
                    print("oops")
                }
            }
        }
    }
    
    // MARK: Offline mode
    func generateOfflineModels() {
        let orgParams = ["name": "Skymall Club"]
        let org = Organization(className: "Organization", dictionary: orgParams)
        
        org.practices = Practice.offlinePractices()
        org.members = Member.offlineMembers()
        org.attendances = Attendance.offlineAttendances()
        
        Organization.current = org
        PFUser.current()?.setObject(org, forKey: "organization")
        
        classNames.removeAll()
        syncComplete()
    }
}
