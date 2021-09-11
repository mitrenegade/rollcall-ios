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
    }

    func testPlusFeaturesAvailable() {
        userService = MockUserService(mockUser: FirebaseUser.plus)
        featureManager = FeatureManager(userService: userService)
        XCTAssertTrue(featureManager.hasEventReminders)
    }

    func testPremiumFeaturesAvailable() {
        userService = MockUserService(mockUser: FirebaseUser.premium)
        featureManager = FeatureManager(userService: userService)
        XCTAssertTrue(featureManager.hasEventReminders)
    }

}
