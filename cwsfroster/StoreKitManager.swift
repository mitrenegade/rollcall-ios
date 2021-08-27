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

    func loadProducts() {
        guard let url = Bundle.main.url(forResource: "subscriptions", withExtension: "plist") else { fatalError("Unable to resolve url for in the bundle.") }
        do {
            let data = try Data(contentsOf: url)
            let productIdentifiers = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String] ?? []

            requestProductsFromStore(productIdentifiers)
        } catch let error as NSError {
            print("\(error.localizedDescription)")
        }
    }

    private func requestProductsFromStore(_ productIDs: [String]) {
         let productIdentifiers = Set(productIDs)

         request = SKProductsRequest(productIdentifiers: productIdentifiers)
         request.delegate = self
         request.start()
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
