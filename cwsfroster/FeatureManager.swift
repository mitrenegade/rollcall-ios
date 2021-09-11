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

    private let userRelay: BehaviorRelay<FirebaseUser> = BehaviorRelay<FirebaseUser>(value: .none)

    private let disposeBag = DisposeBag()

    init(userService: UserServiceProtocol) {
        userService.userObservable
            .asDriver(onErrorJustReturn: .none)
            .drive(userRelay)
            .disposed(by: disposeBag)
    }

    var hasEventReminders: Bool {
        userRelay.value.subscription.hasEventReminders
    }

    var hasPaidEvents: Bool {
        userRelay.value.subscription.hasPaidEvents
    }

    var hasRecurringEvents: Bool {
        userRelay.value.subscription.hasRecurringEvents
    }

    var hasPrepopulateAttendance: Bool {
//        false
        userRelay.value.subscription.hasPrepopulateAttendance
    }
}
