//
//  FeatureManager.swift
//  rollcall
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import RxSwift
import RxCocoa

internal struct FeatureManager {

    static let shared = FeatureManager(userService: UserService.shared)

    private static let noUser = FirebaseUser()

    private let userRelay: BehaviorRelay<FirebaseUser> = BehaviorRelay<FirebaseUser>(value: noUser)

    private let disposeBag = DisposeBag()

    init(userService: UserService) {
        userService.userObservable
            .asDriver(onErrorJustReturn: FeatureManager.noUser)
            .drive(userRelay)
            .disposed(by: disposeBag)
    }

    var hasEventReminders: Bool {
        userRelay.value.subscription.hasEventReminders
    }
}
