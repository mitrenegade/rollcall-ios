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
    
    fileprivate let disposeBag = DisposeBag()
    fileprivate var sessionDisposeBag = DisposeBag()

    var alert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SettingsService.shared.observedSettings?.take(1).subscribe(onNext: {_ in
            print("Settings updated")
        }).disposed(by: disposeBag)

        // always update loading indicator
        OrganizationService.shared
            .loadingObservable
            .subscribe( onNext: { [weak self] loading in
                self?.updateLoading(loading)
            })
            .disposed(by: disposeBag)

        // always update organization image
        OrganizationService.shared
            .organizationObservable
            .map { $0?.photoUrl }
            .subscribe(onNext: { [weak self] url in
                if let url = url, OrganizationService.shared.current?.photoUrl == url {
                    self?.constraintLogoHeight.constant = 500
                    self?.logo.imageUrl = url
                    UIView.animate(withDuration: 0.25, animations: {
                        self?.logo.alpha = 1
                    })
                } else {
                    self?.constraintLogoHeight.constant = 0
                }
            }).disposed(by: disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        activityIndicator.stopAnimating()
        labelInfo.isHidden = true
        labelInfo.text = nil

        listenForLogin()
        listenForLogout()
    }

    func listenForLogout() {
        // listen for logged out state
        print("BOBBYTEST \(self) -> listenForLogout")
        UserService.shared.loginStateObserver
            .filter { $0 == .loggedOut }
            .subscribe(onNext: { _ in
                print("BOBBYTEST \(self) --> logged out")
            })
            .disposed(by: sessionDisposeBag)

        UserService.shared.loginStateObserver
            .filter { $0 == .loggedOut }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.goToLogin()
            })
            .disposed(by: sessionDisposeBag)
    }

    func listenForLogin() {
        UserService.shared.startup()

        // listen for logged in state
        print("BOBBYTEST \(self) -> listenForLogout")
        UserService.shared.loginStateObserver
            .filter { $0 == .loggedIn }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                if let userId = UserService.shared.currentUserID {
                    UserService.shared.startObservingUser(userId)
                }
                self?.listenForOrganization()
            })
            .disposed(by: sessionDisposeBag)
    }

    private func resetSessionDisposeBag() {
        sessionDisposeBag = DisposeBag() // stops listening
    }

    // MARK: -

    func listenForOrganization() {
        print("BOBBYTEST \(self) -> listenForOrganization")
        guard let userId = UserService.shared.currentUserID else {
            fatalError("No userId")
        }
        OrganizationService.shared.startObservingOrganization(for: userId)

        // listen for organization
        OrganizationService.shared.organizationObservable
            .filterNil()
            .subscribe(onNext: { [weak self] _ in
                self?.goHome()
            }).disposed(by: sessionDisposeBag)
    }

    func goHome() {
        resetSessionDisposeBag()
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.goHome()
            }
        } else {
            let mainViewController = MainViewController()
            present(mainViewController, animated: true, completion: nil)

            // listen for a logout
            listenForLogout()
        }
    }

    func goToLogin() {
        resetSessionDisposeBag()
        if presentedViewController != nil {
            dismiss(animated: true) { [weak self] in
                self?.goToLogin()
            }
        } else {
            listenForLogin()
            performSegue(withIdentifier: "toLogin", sender: nil)
        }
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

