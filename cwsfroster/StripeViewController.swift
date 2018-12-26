//
//  StripeViewController.swift
//  rollcall
//
//  Created by Bobby Ren on 12/25/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit
import RenderPay

class StripeViewController: UIViewController {
    
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var buttonConnect: UIButton!
    var stripeService: StripeService?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let clientId = TESTING ? STRIPE_CLIENT_ID_DEV : STRIPE_CLIENT_ID_PROD
        let baseUrl = TESTING ? FIREBASE_URL_DEV : FIREBASE_URL_PROD
        stripeService = StripeService(clientId: clientId, baseUrl: baseUrl)
    }
    
    @IBAction func didClickConnect(_ sender: Any?) {
        guard let orgId = OrganizationService.shared.current.value?.id, let urlString = stripeService?.getOAuthUrl(orgId), let url = URL(string: urlString) else { return }
        UIApplication.shared.openURL(url)
    }
}
