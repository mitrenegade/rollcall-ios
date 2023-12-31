//
//  RollCallTests.swift
//  RollCallTests
//
//  Created by Bobby Ren on 9/10/21.
//  Copyright © 2021 Bobby Ren. All rights reserved.
//

import XCTest
@testable import RollCall

class FeatureManagerTests: XCTestCase {

    var userService: MockUserService!
    var featureManager: FeatureManager!

    override func setUp() {
    }

    override func tearDown() {
        featureManager = nil
        userService = nil
    }

    func testStandardFeaturesAvailable() {
        userService = MockUserService(mockUser: FirebaseUser.standard)
        featureManager = FeatureManager(userService: userService)
        XCTAssertFalse(featureManager.hasEventReminders)
        XCTAssertFalse(featureManager.hasPaidEvents)
        XCTAssertFalse(featureManager.hasRecurringEvents)
        XCTAssertFalse(featureManager.hasPrepopulateAttendance)
    }

    func testPlusFeaturesAvailable() {
        userService = MockUserService(mockUser: FirebaseUser.plus)
        featureManager = FeatureManager(userService: userService)
        XCTAssertTrue(featureManager.hasEventReminders)
        XCTAssertFalse(featureManager.hasPaidEvents)
        XCTAssertTrue(featureManager.hasRecurringEvents)
        XCTAssertTrue(featureManager.hasPrepopulateAttendance)
    }

    func testPremiumFeaturesAvailable() {
        userService = MockUserService(mockUser: FirebaseUser.premium)
        featureManager = FeatureManager(userService: userService)
        XCTAssertTrue(featureManager.hasEventReminders)
        XCTAssertTrue(featureManager.hasPaidEvents)
        XCTAssertTrue(featureManager.hasRecurringEvents)
        XCTAssertTrue(featureManager.hasPrepopulateAttendance)
    }

}
