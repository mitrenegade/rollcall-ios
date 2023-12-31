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

    enum Error: Swift.Error {
        case invalidProduct
    }

    static let shared = StoreKitManager()

    // Keep a strong reference to the product request.
    private var request: SKProductsRequest!

    private (set) var products = [SKProduct]()

    var tiers: Set<SubscriptionProduct> = Set<SubscriptionProduct>()

    override init() {
        super.init()

        SKPaymentQueue.default().add(self)
    }

    func loadProducts() {
        guard let url = Bundle.main.url(forResource: "subscriptions", withExtension: "plist") else { fatalError("Unable to resolve url for in the bundle.") }
        do {
            let data = try Data(contentsOf: url)
            let loadedTiers = try PropertyListDecoder().decode([SubscriptionProduct].self, from: data)
            loadedTiers.forEach { tiers.insert($0) }

            requestProductsFromStore()
        } catch let error as NSError {
            print("\(error.localizedDescription)")
        }
    }

    private func requestProductsFromStore() {
        request?.cancel()
        let productIdentifiers = Set(tiers.compactMap { $0.productId })

        request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }

    /// Maps to the SKProduct for a given SubscriptionProduct, using its productId
    /// - Returns:
    ///     - a `SKProduct` if the SubscriptionProduct has a matching productId, or nil
    func product(for tier: SubscriptionProduct) -> SKProduct? {
        products.first { product -> Bool in
            tier.productId == product.productIdentifier
        }
    }

    /// Maps to the SubscriptionProduct, including a productId, for a given tier (Plus or Premium)
    /// - Returns:
    ///     - a `SubscriptionProduct` or Standard, if no Tiers were loaded in the `subscriptions.plist`
    func subscriptionTier(for tier: Tier) -> SubscriptionProduct? {
        if tier == .standard {
            return .standard
        }
        return tiers.first { $0.tier == tier }
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    // Create the SKProductsRequestDelegate protocol method
    // to receive the array of products.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.isNotEmpty {
            products = response.products
        }

        if response.invalidProductIdentifiers.isNotEmpty {
           // Handle any invalid product identifiers as appropriate.
            print("Error: invalid subscription products: \(response.invalidProductIdentifiers)")
        }
    }
}

// MARK: - Purchase
extension StoreKitManager: SKPaymentTransactionObserver {
    func subscribe(to tier: SubscriptionProduct, completion:((Result<Bool, Error>) -> Void)?) {
        print("Tier pressed \(tier)")

        guard let product = product(for: tier) else {
            completion?(.failure(StoreKitManager.Error.invalidProduct))
            return
        }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("\(self) -> Updated transactions \(transactions)")

        // https://www.raywenderlich.com/5456-in-app-purchase-tutorial-getting-started
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
//                fail(transaction: transaction)
                break
            case .restored:
//                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            @unknown default:
                fatalError("Unknown transaction state")
            }

        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)

        // Temporary: update user transaction via device
        // TODO: call validateReceipt on backend; when it completes successfully,
        // the response should include a new user tier
        if let newTier = tiers.first(where: { tier in
            tier.productId == transaction.payment.productIdentifier
        }) {
            // Need to handle upgrades and downgrades
            UserService.shared.updateUserSubscription(newTier)
        }

        // validate receipt: https://savvyapps.com/blog/how-setup-test-auto-renewable-subscription-ios-app
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {
            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                print(receiptString)

                // TODO: Read receiptData and validate with backend
                
            }
            catch {
                print("Couldn't read receipt data with error: " + error.localizedDescription)
            }
        }
    }
}
