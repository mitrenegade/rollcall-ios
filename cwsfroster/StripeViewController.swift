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
    
    // Setup Stripe
    var isViewSetupVisible: Bool {
        if case .account = accountState {
            return false
        }
        return true
    }
    
    var isLoadingVisible: Bool {
        return accountState == .loading
    }
    
    var isConnectButtonVisible: Bool {
        if case .account = accountState {
            return true
        }
        return false
    }
    
    // Payment history
    var isViewHistoryVisible: Bool {
        if case .account = accountState {
            return true
        }
        return false
    }
    
    var labelInfoText: String {
        switch mode {
        case .week:
            return "Since this week"
        case .all:
            return "Over all time"
        }
    }
}

class StripeViewController: UIViewController {
    
    var stripeService: StripeService?
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
        
        let clientId = TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD
        let baseUrl = TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD
        stripeService = StripeService(clientId: clientId, baseUrl: baseUrl)
        OrganizationService.shared.current.asObservable().filterNil().subscribe(onNext: { [weak self] (org) in
            // start updating StripeService/s accountStatus
            self?.stripeService?.startListeningForAccount(userId: org.id)
            self?.disposeBag = DisposeBag()
            self?.listenForAccount()
        }).disposed(by: disposeBag)
        
        viewIconBG.layer.cornerRadius = viewIconBG.frame.size.height / 2
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))
    }
    
    private func listenForAccount() {
        stripeService?.accountState.asObservable().distinctUntilChanged().subscribe(onNext: { [weak self] (state) in
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
    }
    
    @objc private func close() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didClickConnect(_ sender: Any?) {
        guard let orgId = OrganizationService.shared.current.value?.id, let urlString = stripeService?.getOAuthUrl(orgId), let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func didChangeHistoryMode(_ sender: Any?) {
        refresh()
    }
}
