//
//  SettingsService.swift
//  Balizinha
//
//  Created by Bobby Ren on 9/19/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import RxSwift

fileprivate var singleton: SettingsService?
class SettingsService: NSObject {
    private var remoteConfig = RemoteConfig.remoteConfig()
    static let defaults: [String: Any] = ["newestVersionIOS":"0.1.0", "forceUpgradeVersionIOS": "0.2.0", "softUpgradeInterval": SOFT_UPGRADE_INTERVAL_DEFAULT]

    static var shared: SettingsService {
        if singleton == nil {
            singleton = SettingsService()
        }
        
        return singleton!
    }
    
    // observable
    var observedSettings: Observable<Any>? {
        print("Settings: created observedSettings")
        return Observable.create({ (observer) -> Disposable in
            self.remoteConfig.setDefaults(SettingsService.defaults as? [String : NSObject])
            self.remoteConfig.fetch(completionHandler: { (status, error) in
                self.remoteConfig.activate(completion: nil)
                print("Settings: * newestVersion \(SettingsService.newestVersion)")
                print("Settings: * forceUpgradeVersion \(SettingsService.forceUpgradeVersion)")
                print("Settings: * softUpgradeInterval \(SettingsService.softUpgradeInterval)")
                self.recordExperimentGroups()
                observer.onNext("done")
            })

            return Disposables.create()
        })
    }
    
    fileprivate func featureAvailable(_ feature: String) -> Bool {
        // feature is off by default. feature flags are used to grant access to test features. when a feature is accepted,
        // the feature flag should be removed from the next build. older builds with the feature flagged have to upgrade
        // or they will lose that feature when the config is removed.
        //guard let available = featureFlags[feature] as? Bool else { return true }
        return remoteConfig[feature].boolValue
    }
    
    fileprivate func featureExperiment(_ parameter: String) -> String {
        return remoteConfig[parameter].stringValue ?? ""
    }
    
    fileprivate func featureValue(_ parameter: String) -> RemoteConfigValue {
        return remoteConfig[parameter]
    }
}

// MARK: - Remote settings
extension SettingsService {
    class var newestVersion: String {
        return shared.featureValue("newestVersionIOS").stringValue ?? defaults["newestVersionIOS"] as! String
    }
    
    class var softUpgradeInterval: TimeInterval {
        return shared.featureValue("softUpgradeInterval").numberValue.doubleValue ?? defaults["softUpgardeInterval"] as! TimeInterval
    }
    
    class var forceUpgradeVersion: String {
        return shared.featureValue("forceUpgradeVersionIOS").stringValue ?? defaults["forceUpgradeVersionIOS"] as! String
    }
}

// MARK: - Experiments
extension SettingsService {
    // MARK: - Analytics
    func recordExperimentGroups() {
        let previewGroup = self.featureExperiment("showPreview")
        Analytics.setUserProperty(previewGroup, forName: "ShowPreview")
    }
}

