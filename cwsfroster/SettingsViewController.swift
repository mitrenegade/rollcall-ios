//
//  SettingsViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit
import RACameraHelper
import MessageUI

class SettingsViewController: UITableViewController {
    var cameraHelper: CameraHelper?
    var alert: UIAlertController?

    // TODO: make case iterable
    enum Sections: String {
        case about = "About"
        case organization = "My organization"
        case profile = "My profile"
        case payment = "Payment settings"
        case feedback = "Feedback"
        case logout = "Logout"
    }
    let SECTION_TITLES: [Sections] = [.about, .organization, .profile, .payment, .feedback, .logout]

    func notifyForLogoutInSuccess() {
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        title = "Settings"
        if #available(iOS 13.0, *) {
            let closeButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(didClickClose))
            navigationItem.leftBarButtonItem = closeButtonItem
        } else {
            // Fallback on earlier versions
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func didClickClose() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SECTION_TITLES.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = SECTION_TITLES[indexPath.row].rawValue
        return cell
    }
}

extension SettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.row < SECTION_TITLES.count else { return }
        switch SECTION_TITLES[indexPath.row] {
        case .about:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let message = "Version \(version)\nCopyright RenderApps, LLC 2018";
            simpleAlert("About RollCall", message: message)
            
        case .organization:
            let title = OrganizationService.shared.currentOrganizationName ?? "Your organization"
            let message = "Please select from the following options"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Change name", style: .default, handler: { (action) in
                self.goToUpdateOrganizationName()
            }))
            alert.addAction(UIAlertAction(title: "Change logo", style: .default, handler: { (action) in
                self.setupCameraHelper()
                self.goToUpdateLogo()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)
            {
                alert.popoverPresentationController?.sourceView = tableView
                alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
            }
            present(alert, animated: true, completion: nil)
        case .profile:
            let title = OrganizationService.shared.currentOrganizationName ?? "Your organization"
            let message = "Please select from the following options"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Change email", style: .default, handler: { (action) in
                self.goToUpdateEmail()
            }))
            alert.addAction(UIAlertAction(title: "Change password", style: .default, handler: { (action) in
                self.goToUpdatePassword(nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad)
            {
                alert.popoverPresentationController?.sourceView = tableView
                alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
            }
            present(alert, animated: true, completion: nil)
        case .payment:
            goToPayments()
        case .feedback:
            goToFeedback()
            
        case .logout:
            AuthService.logout()
            notifyForLogoutInSuccess()
        }
    }
}

extension SettingsViewController {
    func goToFeedback() {
        guard let nav = UIStoryboard(name: "Feedback", bundle: nil).instantiateInitialViewController() as? UINavigationController, let _ = nav.viewControllers.first as? FeedbackViewController else { return }
        present(nav, animated: true, completion: nil)
    }

    func goToPayments() {
        guard let nav = UIStoryboard(name: "Stripe", bundle: nil).instantiateInitialViewController() as? UINavigationController, let _ = nav.viewControllers.first as? StripeViewController else { return }
        present(nav, animated: true, completion: nil)
    }

    func goToUpdateOrganizationName() {
        let orgId = OrganizationService.shared.currentOrganizationId
        let orgName = OrganizationService.shared.currentOrganizationName ?? ""
        let title = "Organization: \(orgName)"
        let message = "Please enter new organization name"
        inputPrompt(title: title, message: message) { (newName) in
            guard let name = newName else { return }
            OrganizationService.shared.updateName(name)

            self.simpleAlert("Organization updated", message: "Organization name has been changed to \(name)")
            LoggingService.log(event: .updateOrganizationName, info: ["title": orgId ?? "", "name": name])
            self.notify("organization:name:changed", object: nil, userInfo: nil)
        }
    }
    
    func goToUpdateEmail() {
        guard let email = AuthService.currentUser?.email else { return }
        let title = "Your current login is \(email)"
        let message = "Please enter new login email"
        inputPrompt(title: title, message: message, placeholder: email) { (newEmail) in
            guard let newEmail = newEmail else { return }
            AuthService.currentUser?.updateEmail(to: newEmail, completion: { (error) in
                if let error = error as NSError? {
                    self.simpleAlert("Could not update login", defaultMessage: "Your login could not be updated to \(newEmail)", error: error)
                    LoggingService.log(event: .updateOrganizationEmail, info: ["id": OrganizationService.shared.currentOrganizationId ?? ""], error: error)
                } else {
                    self.simpleAlert("Email login updated", message: "Your new login and email is \(newEmail)")
                    LoggingService.log(event: .updateOrganizationEmail, info: ["id": OrganizationService.shared.currentOrganizationId ?? "", "email": newEmail])
                }
            })
        }
    }

    func goToUpdatePassword(_ entered: String?) {
        let title = entered == nil ? "Update password" : "Confirm password"
        let message = entered == nil ? "Please enter new password" : "Please confirm your new password"
        inputPrompt(title: title, message: message, placeholder: nil) { (newPassword) in
            guard let password = newPassword else { return }
            guard let entered = entered else {
                self.goToUpdatePassword(password)
                return
            }
            guard password == entered else {
                self.simpleAlert("Password mismatch", message: "You must confirm the new password.")
                LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.currentOrganizationId ?? "", "error": "Password confirmation did not match"])
                return
            }
            AuthService.currentUser?.updatePassword(to: password, completion: { (error) in
                if let error = error as NSError? {
                    self.simpleAlert("Could not update password", defaultMessage: "Your password could not be updated.", error: error)
                    LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.currentOrganizationId ?? ""], error: error)
                } else {
                    self.simpleAlert("Password updated", message: nil)
                    LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.currentOrganizationId ?? ""])
                }
            })
        }
    }
    
    fileprivate func inputPrompt(title: String, message: String? = nil, placeholder: String? = nil, completion: @escaping ((String?)->Void)) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = placeholder
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let textField = alert.textFields?.first {
                completion(textField.text)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SettingsViewController: MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
        switch result {
        case .sent:
            simpleAlert("Feedback sent", message: "Thanks for your feedback!")
        case .failed:
            simpleAlert("Could not send feedback", message: "There was an error sending feedback")
        default:
            return
        }
    }
}

// progress
extension SettingsViewController {
    func showProgress(_ title: String?) {
        let alert = UIAlertController(title: title ?? "Progress", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] (action) in
            self?.alert = nil
        })
        
        present(alert, animated: true, completion: nil)
        self.alert = alert
    }
    
    func hideProgress(_ completion:(()->Void)? = nil) {
        if alert == nil {
            completion?()
        } else {
            alert?.dismiss(animated: true, completion: completion)
            alert = nil
        }
    }
    
    func updateProgress(percent: Double = 0) {
        alert?.message = "\(percent * 100)%"
    }
}

extension SettingsViewController: CameraHelperDelegate {
    public func didCancelSelection() {
    }
    
    public func didCancelPicker() {
    }
    
    public func didSelectPhoto(selected: UIImage?) {
        // save image to firebase
        dismiss(animated: false) {
            guard let image = selected else { return }
            self.uploadPhoto(image: image)
        }
    }
    
    func setupCameraHelper() {
        if cameraHelper == nil {
            cameraHelper = CameraHelper()
        }
        cameraHelper?.delegate = self
    }
    
    func goToUpdateLogo() {
        print("UpdateLogo")
        let indexPath = IndexPath(row: SECTION_TITLES.firstIndex(of: .organization)!, section: 0)
        let cell = tableView.cellForRow(at: indexPath)
        cameraHelper?.takeOrSelectPhoto(from: self, fromView: cell)
    }
    
    func uploadPhoto(image: UIImage) {
        guard let id = OrganizationService.shared.currentOrganizationId else { return }
        showProgress("Saving new logo")
        print("FirebaseImageService: uploading org photo for \(id)")
        FirebaseImageService.uploadImage(image: image, type: "organization", uid: id, progressHandler: { (progress) in
            self.updateProgress(percent: progress)
        }) { [weak self] (url) in
            if let url = url {
                OrganizationService.shared.updatePhoto(url)
                print("FirebaseImageService: uploading org photo complete with url \(url)")
                LoggingService.log(event: .updateOrganizationLogo, info: ["title": id])
            } else {
                // failure
                self?.simpleAlert("Upload failed", message: "There was an error uploading a new logo.")
            }
            self?.hideProgress()
        }
    }
}
