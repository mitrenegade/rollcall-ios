//
//  StoreKitManager.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation
import StoreKit

final class StoreKitManager: NSObject {

    static let shared = StoreKitManager()

    // Keep a strong reference to the product request.
    private var request: SKProductsRequest!

    private (set) var products = [SKProduct]()

    var tiers: Set<SubscriptionTier> = Set<SubscriptionTier>()

    func loadProducts() {
        guard let url = Bundle.main.url(forResource: "subscriptions", withExtension: "plist") else { fatalError("Unable to resolve url for in the bundle.") }
        do {
            let data = try Data(contentsOf: url)
            let loadedTiers = try PropertyListDecoder().decode([SubscriptionTier].self, from: data)
            loadedTiers.forEach { tiers.insert($0) }

            requestProductsFromStore()
        } catch let error as NSError {
            print("\(error.localizedDescription)")
        }
    }

    private func requestProductsFromStore() {
        let productIdentifiers = Set(tiers.compactMap { $0.productId })

        request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }

    /// Maps to the SKProduct for a given SubscriptionTier, using its productId
    /// - Returns:
    ///     - a `SKProduct` if the SubscriptionTier has a matching productId, or nil
    func product(for tier: SubscriptionTier) -> SKProduct? {
        products.first { product -> Bool in
            tier.productId == product.productIdentifier
        }
    }

    /// Maps to the SubscriptionTier, including a productId, for a given tier (Plus or Premium)
    /// - Returns:
    ///     - a `SubscriptionTier` or Standard, if no Tiers were loaded in the `subscriptions.plist`
    func subscriptionTier(for tier: Tier) -> SubscriptionTier {
        tiers.first { $0.tier == tier } ?? .standard
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    // Create the SKProductsRequestDelegate protocol method
    // to receive the array of products.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.isNotEmpty {
            products = response.products
            print("BOBBYTEST products \(products)")
        }

        if response.invalidProductIdentifiers.isNotEmpty {
           // Handle any invalid product identifiers as appropriate.
            print("Error: invalid subscription products: \(response.invalidProductIdentifiers)")
        }
    }
}
