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

    private var tierToButton: [SubscriptionTier: UIButton] = [:]

    lazy var subscriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textColor = .white
        return label
    }()

    lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        return label
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
        description.font = .systemFont(ofSize: 14)
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

        view.layer.cornerRadius = 10
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.white.cgColor

        let button: UIButton
        if #available(iOS 14.0, *) {
            let action = UIAction(title: NSLocalizedString("Subscribe", comment: ""), image: nil) { action in
                self.didSelectTier(tier)
            }
            button = UIButton(primaryAction: action)
        } else {
            button = UIButton()
            button.setTitle(NSLocalizedString("Subscribe", comment: ""), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.addTarget(self, action: #selector(didClickButton(_:)), for: .touchUpInside)
            tierToButton[tier] = button
        }
        button.backgroundColor = .lightGray
        button.setTitleColor(.white, for: .normal)
        view.addSubview(button)
        button.layer.cornerRadius = 5
        button.snp.makeConstraints {
            $0.top.equalTo(description.snp.bottom).offset(Layout.topOffset)
            $0.bottom.equalToSuperview().offset(Layout.bottomOffset)
            $0.leading.equalToSuperview().offset(Layout.leadingOffset)
            $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
            $0.height.equalTo(50)
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
        view.addSubview(subscriptionLabel)

        subscriptionLabel.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin).offset(20)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(40)
        }

        view.addSubview(detailsLabel)
        detailsLabel.snp.makeConstraints {
            $0.top.equalTo(subscriptionLabel.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.leading.equalToSuperview().offset(Layout.leadingOffset)
            $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
        }

        var lastView: UIView = detailsLabel
        var offset = Layout.subscriptionTopOffset

        // add plus tier
        if let plus = StoreKitManager.shared.subscriptionTier(for: .plus) {
            let plusView = viewForTier(plus)
            view.addSubview(plusView)
            plusView.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(Layout.leadingOffset)
                $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
                $0.top.equalTo(lastView.snp.bottom).offset(offset)
            }
            lastView = plusView
            offset = Layout.subscriptionSpacing
        }

        // add premium tier
        if let premium = StoreKitManager.shared.subscriptionTier(for: .premium) {
            let premiumView = viewForTier(premium)
            view.addSubview(premiumView)
            premiumView.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(Layout.leadingOffset)
                $0.trailing.equalToSuperview().offset(Layout.trailingOffset)
                $0.top.equalTo(lastView.snp.bottom).offset(Layout.topOffset)
            }
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
        detailsLabel.text = user.subscription.description
    }

    /// only available for iOS 14 because button uses a UIAction
    func didSelectTier(_ tier: SubscriptionTier) {
        print("Tier pressed \(tier)")
    }

    /// for ios 13 and below
    @objc func didClickButton(_ sender: UIButton) {
        for (tier, button) in tierToButton {
            if button == sender {
                print("Tier pressed (\(tier)")
            }
        }
    }

    // MARK: - Navigation

    @objc func didClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

}

extension SubscriptionViewController {
    enum Layout {
        static let leadingOffset: CGFloat = 16.0
        static let trailingOffset: CGFloat = -16.0
        static let topOffset: CGFloat = 8.0
        static let bottomOffset: CGFloat = -16.0

        static let subscriptionTopOffset: CGFloat = 24.0
        static let subscriptionSpacing: CGFloat = 16.0
    }
}
