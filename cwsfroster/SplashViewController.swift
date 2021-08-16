//
//  SplashViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import RxOptional
import Firebase

class SplashViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var logo: RAImageView!
    
    @IBOutlet weak var constraintLogoHeight: NSLayoutConstraint!
    
    var first: Bool = true
    
    fileprivate var disposeBag = DisposeBag()
    
    var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor(.LoginSuccess, action: #selector(didLogin(_:)), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)
        
        SettingsService.shared.observedSettings?.take(1).subscribe(onNext: {_ in
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
        
        guard firAuth.currentUser != nil else { return }
        if OrganizationService.shared.current.value != nil {
            goHome()
        } else {
            self.didLogin(nil)
        }

    }
    
    func goHome() {
        disposeBag = DisposeBag() // stops listening
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        } else {
            if AuthService.isLoggedIn {
                guard let shellViewController = UIStoryboard(name: "Main", bundle: nil)
                        .instantiateInitialViewController() else {
                    fatalError("Could not instantiate shell")
                }
                present(shellViewController, animated: true, completion: nil)
            } else {
                performSegue(withIdentifier: "toLogin", sender: nil)
            }
        }
    }
    
    @objc func didLogin(_ notification: NSNotification?) {
        // update firebase object
        activityIndicator.startAnimating()
        labelInfo.isHidden = false
        labelInfo.text = "Loading organization"
        OrganizationService.shared.startObservingOrganization()
        OrganizationService.shared
            .current
            .asObservable()
            .distinctUntilChanged()
            .filterNil()
            .subscribe(onNext: { [weak self] (org) in
                if let url = org.photoUrl {
                    self?.constraintLogoHeight.constant = 500
                    self?.logo.imageUrl = url
                    UIView.animate(withDuration: 0.25, animations: {
                        self?.logo.alpha = 1
                    }, completion: { (success) in
                        self?.goHome()
                    })
                } else {
                    self?.constraintLogoHeight.constant = 0
                    self?.goHome()
                }
            }).disposed(by: disposeBag)
        
        OrganizationService.shared.current.asObservable().skip(1).subscribe(onNext: { (org) in
            if org == nil, let userId = AuthService.currentUser?.uid, let orgName = AuthService.currentUser?.email {
                AuthService.createFirebaseUser(id: userId)
                OrganizationService.shared.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
            }
        }).disposed(by: disposeBag)
    }
    
    @objc func didLogout() {
        print("logged out")
        goHome()
    }
    
    deinit {
        stopListeningFor(.LoginSuccess)
        stopListeningFor(.LogoutSuccess)
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

