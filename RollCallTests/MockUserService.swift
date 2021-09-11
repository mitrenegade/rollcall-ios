//
//  MockUserService.swift
//  RollCallTests
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
@testable import RollCall

internal struct MockUserService: UserServiceProtocol {
    var isLoggedIn: Bool = true

    var mockSubscription: SubscriptionProduct?
    var currentSubscription: SubscriptionProduct? {
        mockSubscription
    }

    let mockUser: FirebaseUser
    var userObservable: Observable<FirebaseUser> {
        .just(mockUser)
    }

    init(mockUser: FirebaseUser) {
        self.mockUser = mockUser
    }
}

extension FirebaseUser {
    static let standard: FirebaseUser = FirebaseUser(id: "1",
                                                     dict: ["subscription": "standard"])
    static let plus: FirebaseUser = FirebaseUser(id: "1",
                                                 dict: ["subscription": "plus"])
    static let premium: FirebaseUser = FirebaseUser(id: "1",
                                                    dict: ["subscription": "premium"])
}
