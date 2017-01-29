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
            Organization.createOrganization(completion: { (org) in
                self.synchronizeWithParse()
            })
            return
        }

        orgPointer.fetchInBackground { (object, error) in
            guard let org = object else { return }
            ParseBase.synchronizeClass("Organization", from: [org], replaceExisting: true) {
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
                
                self.synchronizeClasses(classNames: ["Member", "Practice", "Attendance", "Payment"], org: org)
            }
        }
    }
    
    private func synchronizeClasses(classNames: [String], org: PFObject) {
        var classNames = classNames
        guard classNames.count > 0 else {
            self.activityIndicator.stopAnimating()
            self.labelInfo.isHidden = true
            self.labelInfo.text = nil
            goHome()
            return
        }

        // make sure Member, Practice, Attendance, Payment exist
        guard let className = classNames.first else { return }
        
        classNames.remove(at: 0)
        labelInfo.text = "Loading " + className.lowercased() + "s"
        let query = PFQuery(className: className)
        query.whereKey("organization", equalTo: org)
        
        query.findObjectsInBackground(block: { (results, error) in
            if let error = error as? NSError {
                print("Error \(error)")
            }
            else {
                ParseBase.synchronizeClass(className, from: results, replaceExisting: true, completion: nil)
                self.synchronizeClasses(classNames: classNames, org: org)
            }
        })
    }
}
