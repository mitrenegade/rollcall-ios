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

    lazy var subscriptionLabel: UILabel = {
        UILabel()
    }()

    lazy var detailsLabel: UILabel = {
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

    private func viewForTier(_ tier: SubscriptionTier) -> UIView {
        let view = UIView()

        let title = UILabel()
        title.font = .systemFont(ofSize: 16)
        title.textColor = .white
        title.text = tier.tier.rawValue.uppercased()

        view.addSubview(title)
        title.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(Layout.topOffset)
            $0.height.equalTo(30)
        }

        let description = UILabel()
        description.font = .systemFont(ofSize: 16)
        description.textColor = .white
        description.text = tier.description
        description.numberOfLines = 0

        view.addSubview(description)
        description.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(title.snp.bottom).offset(Layout.topOffset)
            $0.leading.equalToSuperview().offset(Layout.leadingOffset)
            $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
        }

        return view
    }

    private func setupViews() {
        navigationItem.title = "Your Subscription"

        view.backgroundColor = .bgBlue

        view.addSubview(subscriptionLabel)
        subscriptionLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
        subscriptionLabel.font = .systemFont(ofSize: 20)
        subscriptionLabel.textColor = .white
        view.addSubview(subscriptionLabel)

        subscriptionLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }
        subscriptionLabel.font = .systemFont(ofSize: 20)
        subscriptionLabel.textColor = .white

        let stackView = UIStackView()
        stackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Layout.leadingOffset)
            $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
            $0.top.equalTo(subscriptionLabel.snp.bottom)
            $0.bottom.equalToSuperview().offset(Layout.bottomOffset)
        }
    }

    private func setupBindings() {
        UserService.shared.userObservable
            .subscribe(onNext: { [weak self] user in
                self?.update(for: user)
            })
            .disposed(by: disposeBag)
    }

    func update(for user: FirebaseUser) {
        subscriptionLabel.text = user.subscription.tier.rawValue.uppercased()

    }

    // MARK: - Navigation

    @objc func didClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

}

extension SubscriptionViewController {
    enum Layout {
        static let leadingOffset: CGFloat = 16.0
        static let trailingOffset: CGFloat = 16.0
        static let topOffset: CGFloat = 8.0
        static let bottomOffset: CGFloat = 16.0
    }
}
