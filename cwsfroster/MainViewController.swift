//
//  MainViewController.swift
//  rollcall
//
//  Created by Ren, Bobby on 6/1/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import RxSwift
import Firebase

class MainViewController: UITabBarController {
    var disposeBag: DisposeBag = DisposeBag()
    fileprivate var upgradeShown: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        listenFor("organization:name:changed", action: #selector(updateTabBarIcons), object: nil)
        listenFor("goToSettings", action: #selector(goToSettings), object: nil)
        listenFor(.LogoutSuccess, action: #selector(didLogout), object: nil)

        if UserDefaults.standard.bool(forKey: "organization:is:new") {
            selectedIndex = 1
        }

        setupViews()
        
        updateTabBarIcons()
        
        listenForOrganization()
    }
    
    @objc func didLogout() {
        // this causes listenForOrganization to be successfully cleared even if ShellViewController is not actually correctly deallocated on logout (corner case)
        disposeBag = DisposeBag()
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
            
            if let name = OrganizationService.shared.currentOrganizationName {
                let title = "Welcome to \(name)"
                simpleAlert(title, message: "Add some members to your new organization")
            }
        }
        
        UpgradeService().promptForUpgradeIfNeeded(from: self)
    }

    func listenForOrganization() {
        print("Listening for organization")
        OrganizationService.shared
            .currentObservable
            .subscribe(onNext: { (org) in
                print("Listening for organization -> title: \(String(describing: org?.name))")
            }).disposed(by: disposeBag)
    }

    private func setupViews() {
        guard let membersViewController = UIStoryboard(name: "Members", bundle: nil)
                .instantiateInitialViewController() as? MembersTableViewController,
              let eventsViewController = UIStoryboard(name: "Events", bundle: nil)
                .instantiateInitialViewController() as? EventsListViewController else {
            return
        }
        viewControllers = [UINavigationController(rootViewController: eventsViewController),
                           UINavigationController(rootViewController: membersViewController)]
    }
    
    @objc func updateTabBarIcons() {
        guard let name = OrganizationService.shared.currentOrganizationName else { return }
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
    
    @objc func goToSettings() {
        let settingsViewController = SettingsViewController(nibName: nil, bundle: nil)
        present(UINavigationController(rootViewController: settingsViewController),
                animated: true,
                completion: nil)
    }

}
