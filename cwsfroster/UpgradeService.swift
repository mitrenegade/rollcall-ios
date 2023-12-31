//
//  UpgradeService.swift
//  Balizinha
//
//  Created by Bobby Ren on 4/8/18.
//  Copyright © 2018 Bobby Ren. All rights reserved.
//

import UIKit

class UpgradeService: NSObject {
    fileprivate let currentVersion: String!
    fileprivate let newestVersion: String?
    fileprivate let forceUpgradeVersion: String?
    fileprivate let upgradeInterval: TimeInterval!
    fileprivate let defaults: UserDefaults!
    init(currentVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown", newestVersion: String = SettingsService.newestVersion, forceUpgradeVersion: String = SettingsService.forceUpgradeVersion, upgradeInterval: TimeInterval = SettingsService.softUpgradeInterval, defaults: UserDefaults = UserDefaults.standard) {
        self.currentVersion = currentVersion
        self.newestVersion = newestVersion
        self.forceUpgradeVersion = forceUpgradeVersion
        self.upgradeInterval = upgradeInterval
        self.defaults = defaults
        
        super.init()
    }
    
    // condition 1: newer version is available
    var newerVersionAvailable: Bool {
        guard let newestVersion = newestVersion else { return false }
        return currentVersion < newestVersion
    }
    
    // condition 2: enough time has passed since last soft upgrade message
    var softUpgradeTimeElapsed: Bool {
        guard let timestamp: Date = defaults.value(forKey: "softUpgradeLastViewTimestamp") as? Date else { return true }
        guard let interval: TimeInterval = upgradeInterval else { return true }
        return Date().timeIntervalSince(timestamp) > interval
    }
    
    // condition 3: user has not opted to never see soft upgrade message
    var neverShowSoftUpgrade: Bool {
        return defaults.bool(forKey: "neverShowSoftUpgrade")
    }
    
    var shouldShowSoftUpgrade: Bool {
        guard newerVersionAvailable else { return false }
        guard softUpgradeTimeElapsed else { return false }
        guard !neverShowSoftUpgrade else { return false }
        guard !shouldShowForceUpgrade else { return false }
        
        return true
    }
    
    var shouldShowForceUpgrade: Bool {
        guard let upgradeVersion = forceUpgradeVersion else { return false }
        return currentVersion < upgradeVersion
    }
    
    // after user dismisses Soft Upgrade, set default values as needed
    func softUpgradeDismissed(neverShowAgain: Bool) {
        defaults.set(Date(), forKey: "softUpgradeLastViewTimestamp")
        defaults.set(neverShowAgain, forKey: "neverShowSoftUpgrade")
        defaults.synchronize()
    }
    
    func clearOnLogout() {
        defaults.set(nil, forKey: "softUpgradeLastViewTimestamp")
        defaults.set(nil, forKey: "neverShowSoftUpgrade")
        defaults.synchronize()
    }
}

// helpers
extension UpgradeService {
    func promptForUpgradeIfNeeded(from controller: UIViewController) {
        guard shouldShowSoftUpgrade || shouldShowForceUpgrade else { return }
        
        let title = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "RollCall"
        let version = shouldShowForceUpgrade ? SettingsService.forceUpgradeVersion : SettingsService.newestVersion
        let alert = UIAlertController(title: "Upgrade available", message: "There is a newer version (\(version)) of \(title) available in the App Store.", preferredStyle: .alert)
        if let url = URL(string: APP_STORE_URL), UIApplication.shared.canOpenURL(url)
        {
            alert.addAction(UIAlertAction(title: "Open in App Store", style: .default, handler: { (action) in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                LoggingService.log(event: .softUpgradeDismissed, info: ["action": "appStore"])
                self.softUpgradeDismissed(neverShowAgain: false)
            }))
        }
        if shouldShowSoftUpgrade {
            alert.addAction(UIAlertAction(title: "Do not show again", style: .default, handler: { (action) in
                self.softUpgradeDismissed(neverShowAgain: true)
                LoggingService.log(event: .softUpgradeDismissed, info: ["action": "neverShowAgain"])
            }))
            alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action) in
                self.softUpgradeDismissed(neverShowAgain: false)
                LoggingService.log(event: .softUpgradeDismissed, info: ["action": "later"])
            }))
        }
        controller.present(alert, animated: true)
        LoggingService.log(event: .upgradeDisplayed, info: ["type": shouldShowForceUpgrade ? "force" : "soft"])
    }
}
