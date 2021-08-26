//
//  SubscriptionViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import RxSwift
import RxCocoa
import SnapKit

final class SubscriptionViewController: UIViewController {

    // MARK: - Properties

    private let disposeBag = DisposeBag()

    lazy var titleLabel: UILabel = {
        UILabel()
    }()

    // MARK: - Lifecycle

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

        view.backgroundColor = .bgBlue

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
        titleLabel.font = .systemFont(ofSize: 20)
        titleLabel.textColor = .white
    }

    private func setupBindings() {
        OrganizationService.shared.currentObservable
            .subscribe(onNext: { [weak self] organization in
                self?.update(for: organization)
            })
            .disposed(by: disposeBag)
    }

    func update(for organization: FirebaseOrganization?) {
        guard let organization = organization else {
            AuthService.logout()
            notify(.LogoutSuccess, object: nil, userInfo: nil)
            didClickClose()
            return
        }

        switch organization.subscription {
        case .standard:
            titleLabel.text = "Standard"
        case .plus:
            titleLabel.text = "Plus"
        case .premium:
            titleLabel.text = "Premium"
        }
    }

    // MARK: - Navigation

    @objc func didClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

}
