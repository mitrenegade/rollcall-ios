//
//  StripeViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 12/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import RenderPay
import RxSwift

enum PaymentHistoryMode {
    case week
    case all
}

class StripeConnectViewModel {
    var accountState: AccountState
    var mode: PaymentHistoryMode
    init(state: AccountState, mode: PaymentHistoryMode) {
        accountState = state
        self.mode = mode
    }
    
    private var hasAccount: Bool {
        if case .account = accountState {
            return true
        }
        return false
    }
    
    // Setup Stripe
    var isViewSetupVisible: Bool {
        return !hasAccount
    }
    
    var isLoadingVisible: Bool {
        return accountState == .loading
    }
    
    var isConnectButtonVisible: Bool {
        if accountState == .none || accountState == .unknown {
            return true
        }
        return false
    }
    
    // Payment history
    var isViewHistoryVisible: Bool {
        return hasAccount
    }
    
    var labelInfoText: String {
        switch mode {
        case .week:
            return "Since this week"
        case .all:
            return "Over all time"
        }
    }
    
    var isSettingsVisible: Bool {
        return hasAccount
    }
}

class StripeViewController: UIViewController {
    
    private let stripePaymentService = Globals.stripePaymentService
    private let stripeConnectService = Globals.stripeConnectService
    var accountState: AccountState = .unknown
    
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var viewSetup: UIView!
    @IBOutlet weak var labelLoading: UIView!
    @IBOutlet weak var viewIconBG: UIView!
    @IBOutlet weak var imageViewIcon: UIImageView!
    @IBOutlet weak var buttonConnect: UIButton!

    @IBOutlet weak var viewTotalPayments: UIView!
    @IBOutlet weak var selectorTime: UISegmentedControl!
    @IBOutlet weak var labelAmount: UILabel!
    @IBOutlet weak var labelInfo: UILabel!
    
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        OrganizationService.shared.current.asObservable().filterNil().subscribe(onNext: { [weak self] (org) in
            // start updating StripeService/s accountStatus
            self?.stripeConnectService.startListeningForAccount(userId: org.id)
            self?.disposeBag = DisposeBag()
            self?.listenForAccount()
        }).disposed(by: disposeBag)
        
        viewIconBG.layer.cornerRadius = viewIconBG.frame.size.height / 2
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
        refresh()
    }
    
    private func listenForAccount() {
        stripeConnectService.accountState.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (state) in
            self?.accountState = state
            self?.refresh()
        }).disposed(by: disposeBag)
    }
    
    private func refresh() {
        let mode: PaymentHistoryMode
        switch selectorTime.selectedSegmentIndex {
        case 0:
            mode = .week
        case 1:
            mode = .all
        default:
            mode = .all
        }
        let viewModel = StripeConnectViewModel(state: accountState, mode: mode)
        
        viewSetup.isHidden = !viewModel.isViewSetupVisible
        labelLoading.isHidden = !viewModel.isLoadingVisible
        buttonConnect.isHidden = !viewModel.isConnectButtonVisible
        
        viewTotalPayments.isHidden = !viewModel.isViewHistoryVisible
        labelInfo.text = viewModel.labelInfoText
        
        setupSettingsNavButton(isVisible: viewModel.isSettingsVisible)
    }
    
    @objc private func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    private func setupSettingsNavButton(isVisible: Bool) {
        if isVisible {
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            button.setImage(UIImage(named: "settingsIcon30"), for: .normal)
            button.addTarget(self, action: #selector(goToSettings), for: .touchUpInside)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc private func goToSettings() {
        // TODO: give user the option to disconnect
        if case .account(let id) = accountState {
            simpleAlert("Stripe connected", message: "Current Stripe account is \(id)")
        }
    }
    
    @IBAction func didClickConnect(_ sender: Any?) {
        guard let orgId = OrganizationService.shared.current.value?.id else { return }
        stripeConnectService.connectToAccount(orgId)
    }
    
    @IBAction func didChangeHistoryMode(_ sender: Any?) {
        refresh()
    }
}
