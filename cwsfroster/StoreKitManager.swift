//
//  StoreKitManager.swift
//  rollcall
//
//  Created by Bobby Ren on 8/25/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation
import StoreKit

final class StoreKitManager {
    static let shared = StoreKitManager()

    func loadProducts() {
        guard let url = Bundle.main.url(forResource: "subscriptions", withExtension: "plist") else { fatalError("Unable to resolve url for in the bundle.") }
        do {
            let data = try Data(contentsOf: url)
            let productIdentifiers = try PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil) as? [String]

            requestProductsFromStore(productIdentifiers)
        } catch let error as NSError {
            print("\(error.localizedDescription)")
        }
    }

    private func requestProductsFromStore(_ productIDs: [String]?) {
        print("BOBBYTEST request \(productIDs)")
    }
}
