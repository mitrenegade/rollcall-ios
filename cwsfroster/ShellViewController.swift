//
//  ShellViewController.swift
//  rollcall
//
//  Created by Ren, Bobby on 6/1/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import Firebase

class ShellViewController: UITabBarController {
    var disposeBag: DisposeBag? = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor("organization:name:changed", action: #selector(updateTabBarIcons), object: nil)
        listenFor("goToSettings", action: #selector(goToSettings), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)

        if UserDefaults.standard.bool(forKey: "organization:is:new") {
            selectedIndex = 1
        }
        
        updateTabBarIcons()
        
        listenForOrganization()
    }
    
    deinit {
        // FIXME: for some reason, presenting ShellViewController on SplashViewController causes ShellViewController to never deallocate. maybe it's because of the mix of objc and swift classes? As a result, disposeBag is never deallocated, and listeners and observers never stop observing. We have to force that to happen on logout
        print("deinit succeess")
    }
    
    func didLogout() {
        // this causes listenForOrganization to be successfully cleared even if ShellViewController is not actually correctly deallocated on logout (corner case)
        disposeBag = nil
        print("here didlogout")
        stopListeningFor("organization:name:changed")
        stopListeningFor("goToSettings")
        stopListeningFor(.LogoutSuccess)
        
        UpgradeService().clearOnLogout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if UserDefaults.standard.bool(forKey: "organization:is:new") {
            UserDefaults.standard.set(false, forKey: "organization:is:new")
            UserDefaults.standard.synchronize()
            
            if let name = OrganizationService.shared.current.value?.name {
                let title = "Welcome to \(name)"
                simpleAlert(title, message: "Add some members to your new organization")
            }
        }
        
        self.promptForUpgradeIfNeeded()
    }
    
    fileprivate func promptForUpgradeIfNeeded() {
        guard UpgradeService().shouldShowSoftUpgrade else { return }
        
        let title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "Balizinha"
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
                UpgradeService().softUpgradeDismissed(neverShowAgain: false)
            }))
        }
        alert.addAction(UIAlertAction(title: "Do not show again", style: .default, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: true)
            LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "neverShowAgain"])
        }))
        alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
            UpgradeService().softUpgradeDismissed(neverShowAgain: false)
            LoggingService.shared.log(event: .softUpgradeDismissed, info: ["action": "later"])
        }))
        present(alert, animated: true)
    }
    func listenForOrganization() {
        print("Listening for organization")
        guard let disposeBag = disposeBag else { return }
        OrganizationService.shared.current.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (org) in
            print("Listening for organization -> title: \(org?.name)")
        }).disposed(by: disposeBag)
    }
    
    func updateTabBarIcons() {
        guard let name = OrganizationService.shared.current.value?.name else { return }
        if name.lowercased().contains("taekwondo") {
            setIcon(iconName: "icon-tkd-paddle", for: 0)
            setIcon(iconName: "icon-tkd-helmet", for: 1)
        } else {
            setIcon(iconName: "icon-calendar", for: 0)
            setIcon(iconName: "icon-users", for: 1)
        }
    }

    func setIcon(iconName: String, for index: Int) {
        guard let controller = viewControllers?[index] else { return }
        let image = UIImage(named: iconName)
        controller.tabBarItem.image = image
        controller.tabBarItem.selectedImage = image
    }
    
    func goToSettings() {
        if let nav = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() {
            present(nav, animated: true, completion: nil)
        }
    }
}
