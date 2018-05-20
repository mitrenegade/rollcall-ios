//
//  SplashViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class SplashViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var logo: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.activityIndicator.stopAnimating()
        self.labelInfo.isHidden = true
        self.labelInfo.text = nil
        if AuthService.isLoggedIn {
            self.synchronizeWithParse()
        }
        else {
            self.goHome()
        }
    }
    
    func goHome() {
        guard let homeViewController = homeViewController() else { return }
        if let presented = presentedViewController {
            guard homeViewController != presented else { return }
            dismiss(animated: true, completion: nil)
        } else {
            present(homeViewController, animated: true, completion: nil)
        }
    }
    
    fileprivate func homeViewController() -> UIViewController? {
        if AuthService.isLoggedIn {
            return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        } else {
            return UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
        }
    }
    
    func didLogin() {
        print("logged in")
        if AuthService.isLoggedIn {
            self.synchronizeWithParse()
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
    func synchronizeWithParse() {
        guard !OFFLINE_MODE else {
            self.generateOfflineModels()
            return
        }
        
        classNames = ["members", "practices", "attendances"]
        self.activityIndicator.startAnimating()
        self.labelInfo.isHidden = false
        
        guard let user = PFUser.current() else {
            if AuthService.isLoggedIn {
                activityIndicator.stopAnimating()
                goHome()
            }
            return
        }

        // make sure org exists
        guard let orgPointer: PFObject = user.object(forKey: "organization") as? PFObject else {
            labelInfo.text = "Creating organization"
            let org = Organization()
            org.name = user.username
            org.saveInBackground(block: { (success, error) in
                if success {
                    user.setObject(org, forKey: "organization")
                    user.saveEventually()
                    self.synchronizeWithParse()
                }
                else {
                    self.synchronizeWithParse()
                }
            })
            return
        }
        
        orgPointer.fetchInBackground { (object, error) in
            guard let org = object as? Organization else {
                self.simpleAlert("Invalid organization", message: "We could not log you in or load your organization. Please try again.", completion: {
                    AuthService.logout()
                    self.didLogout()
                })
                return
            }
            Organization.current = org
            

            if let imageFile: PFFile = org.object(forKey: "logoData") as? PFFile {
                do {
                    let data = try imageFile.getData()
                    if let image = UIImage(data: data) {
                        self.logo.image = image
                        UIView.animate(withDuration: 0.25, animations: {
                            self.logo.alpha = 1
                        })
                        self.syncParseObjects()
                    }
                    else {
                        print("no image")
                        self.syncParseObjects()
                    }
                }
                catch {
                    print("some error")
                    self.syncParseObjects()
                }
            }
            else {
                self.syncParseObjects()
                self.logo.alpha = 0;
                self.logo.image = nil
            }
        }
    }
    
    func syncParseObjects() {
        self.labelInfo.text = "Loading..."
        Organization.queryForMembers(completion: { (results, error) in
            classNames.remove(at: classNames.index(of: "members")!)
            self.labelInfo.text = "Loaded members"
            if let members = results {
                Organization.current?.members = members
            }
            self.checkSyncComplete()
        })
        
        Organization.queryForPractices(completion: { (results, error) in
            classNames.remove(at: classNames.index(of: "practices")!)
            self.labelInfo.text = "Loaded practices"
            if let practices = results {
                Organization.current?.practices = practices
            }
            self.checkSyncComplete()
        })
        
        Organization.queryForAttendances(completion: { (results, error) in
            classNames.remove(at: classNames.index(of: "attendances")!)
            self.labelInfo.text = "Loaded attendances"
            if let attendances = results {
                Organization.current?.attendances = attendances
            }
            self.checkSyncComplete()
        })
    }
    
    func checkSyncComplete() {
        if classNames.count == 0 {
            self.activityIndicator.stopAnimating()
            self.labelInfo.isHidden = true
            self.labelInfo.text = nil
            self.goHome()
            return
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
        self.checkSyncComplete()
    }
}
