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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        goHome()
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
            // PFUser.currentUser is only a PFUser. This case should not exist
            return UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        }
    }
    
    func didLogin() {
        print("logged in")
        goHome()
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
