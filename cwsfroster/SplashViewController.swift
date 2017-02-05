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
        if PFUser.current() != nil {
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
        switch PFUser.current() {
        case .none:
            return UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
        default:
            return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }
    
    func didLogin() {
        print("logged in")
        if PFUser.current() != nil {
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
extension SplashViewController {
    func synchronizeWithParse() {
        self.activityIndicator.startAnimating()
        self.labelInfo.isHidden = false
        
        guard let user = PFUser.current() else { return }

        // make sure org exists
        guard let orgPointer: PFObject = user.object(forKey: "organization") as? PFObject else {
            labelInfo.text = "Creating organization"
            let org = Organization()
            user.setObject(org, forKey: "organization")
            self.synchronizeWithParse()
            return
        }

        orgPointer.fetchInBackground { (object, error) in
            guard let org = object as? Organization else { return }
            Organization.current = org
            if let imageFile: PFFile = org.object(forKey: "logoData") as? PFFile {
                imageFile.getDataInBackground(block: { (data, error) in
                    // TODO: Load org image
                    /*
                     logo.alpha = 0;
                     UIImage *image = [UIImage imageWithData:data];
                     [logo setImage:image];
                     [UIView animateWithDuration:1 animations:^{
                     logo.alpha = 1;
                     } completion:^(BOOL finished) {
                     }];
                     */
                })
            }
            
            self.labelInfo.text = "Loading..."
            var classNames = ["members", "practices", "attendances"]
            Organization.queryForMembers(completion: { (results, error) in
                classNames.remove(at: classNames.index(of: "members")!)
                self.labelInfo.text = "Loaded members"
                if let members = results {
                    org.members = members
                    if classNames.count == 0 {
                        self.activityIndicator.stopAnimating()
                        self.labelInfo.isHidden = true
                        self.labelInfo.text = nil
                        self.goHome()
                        return
                    }
                }
            })
            
            Organization.queryForPractices(completion: { (results, error) in
                classNames.remove(at: classNames.index(of: "practices")!)
                self.labelInfo.text = "Loaded practices"
                if let practices = results {
                    org.practices = practices
                    if classNames.count == 0 {
                        self.activityIndicator.stopAnimating()
                        self.labelInfo.isHidden = true
                        self.labelInfo.text = nil
                        self.goHome()
                        return
                    }
                }
            })
            
            Organization.queryForAttendances(completion: { (results, error) in
                classNames.remove(at: classNames.index(of: "attendances")!)
                self.labelInfo.text = "Loaded attendances"
                if let attendances = results {
                    org.attendances = attendances
                    if classNames.count == 0 {
                        self.activityIndicator.stopAnimating()
                        self.labelInfo.isHidden = true
                        self.labelInfo.text = nil
                        self.goHome()
                        return
                    }
                }
            })
        }
    }
}
