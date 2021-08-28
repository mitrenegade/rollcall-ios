//
//  SplashViewController.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
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

        listenForLoginState()
    }

    func listenForLoginState() {
        // listen for login
        print("BOBBYTEST \(self) -> listenForUser")
        UserService.shared.startup()

        // listen for logged in state
        UserService.shared.loginStateObserver
            .filter { $0 == .loggedIn }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.listenForOrganization()
            })
            .disposed(by: disposeBag)

        // listen for logged out state
        UserService.shared.loginStateObserver
            .filter { $0 == .loggedOut }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.goHome()
            })
            .disposed(by: disposeBag)
    }

    func listenForOrganization() {
        print("BOBBYTEST \(self) -> listenForOrganization")
        guard let userId = UserService.shared.currentUserID else {
            fatalError("No userId")
        }
        OrganizationService.shared.startObservingOrganization(for: userId)

        // listen for organization
        OrganizationService.shared.currentObservable
            .subscribe(onNext: { [weak self] org in
                if org != nil {
                    self?.goHome()
                } else {
                    self?.didLogin(nil)
                }
            }).disposed(by: disposeBag)
    }

    func goHome() {
        disposeBag = DisposeBag() // stops listening
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.goHome()
            }
        } else {
            if UserService.shared.isLoggedIn {
                let mainViewController = MainViewController()
                present(mainViewController, animated: true, completion: nil)
            } else {
                performSegue(withIdentifier: "toLogin", sender: nil)
            }
        }
    }
    
    @objc func didLogin(_ notification: NSNotification?) {
        // update firebase object
        guard let userId = UserService.shared.currentUserID else {
            print("UserId doesn't exist while observing org; logging out")
            UserService.shared.logout()
            return
        }

        OrganizationService.shared.startObservingOrganization(for: userId)
        OrganizationService.shared
            .loadingObservable
            .subscribe( onNext: { [weak self] loading in
                self?.updateLoading(loading)
            })
            .disposed(by: disposeBag)

        OrganizationService.shared
            .currentObservable
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

        // create org for users without orgs
        OrganizationService.shared
            .currentObservable
            .skip(1)
            .subscribe(onNext: { (org) in
                if org == nil, let userId = UserService.shared.currentUserID, let orgName = UserService.shared.currentUserEmail {
                    UserService.shared.createOrUpdateFirebaseUser(id: userId)
                    OrganizationService.shared.createOrUpdateOrganization(orgId: userId, ownerId: userId, name: orgName, leftPowerUserFeedback: false)
                }
            }).disposed(by: disposeBag)
    }
    
    @objc func didLogout() {
        goHome()
    }

    private func updateLoading(_ loading: Bool) {
        if loading {
            activityIndicator.startAnimating()
            labelInfo.isHidden = false
            labelInfo.text = "Loading organization"
        } else {
            activityIndicator.stopAnimating()
            labelInfo.isHidden = true
            labelInfo.text = nil
        }
    }

    deinit {
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

