//
//  SubscriptionViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation

final class SubscriptionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigation()
        setupViews()
        setupBindings()
    }

    private func setupNavigation() {
        if #available(iOS 13.0, *) {
            let closeButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didClickClose))
            navigationItem.leftBarButtonItem = closeButtonItem
        } else {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didClickClose))
        }
    }

    private func setupViews() {
        navigationItem.title = "Your Subscription"
    }

    private func setupBindings() {

    }

    // MARK: - Navigation

    @objc func didClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

}
