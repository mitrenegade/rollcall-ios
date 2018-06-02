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
    let disposeBag: DisposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.listenFor("organization:name:changed", action: #selector(updateTabBarIcons), object: nil)
        self.listenFor("goToSettings", action: #selector(goToSettings), object: nil)
        
        if UserDefaults.standard.bool(forKey: "organization:is:new") {
            self.selectedIndex = 1
        }
        
        self.updateTabBarIcons()
        
        self.listenForOrganization()
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
    }
    
    func listenForOrganization() {
        OrganizationService.shared.current.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (org) in
            print("Org title: \(org?.name)")
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
        guard let controller = self.viewControllers?[index] else { return }
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
