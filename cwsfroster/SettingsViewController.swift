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

class SettingsViewController: UITableViewController {
    var cameraHelper: CameraHelper?
    var alert: UIAlertController?

    // TODO: make case iterable
    enum Sections: String {
        case about = "About"
        case organization = "My organization"
        case account = "My account"
        case feedback = "Feedback"
        case logout = "Logout"
    }
    let SECTION_TITLES: [Sections] = [.about, .organization, .account, .feedback, .logout]

    func notifyForLogoutInSuccess() {
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
    }
    
    @IBAction func didClickClose() {
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
            guard let org =  OrganizationService.shared.current.value else { return }
            let title = org.name ?? "Your nrganization"
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
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad)
            {
                if let cell = tableView.cellForRow(at: indexPath) {
                    alert.popoverPresentationController?.sourceView = cell
                    alert.popoverPresentationController?.sourceRect = cell.frame
                }
            }
            present(alert, animated: true, completion: nil)
        case .account:
            guard let org =  OrganizationService.shared.current.value else { return }
            let title = org.name ?? "Your organization"
            let message = "Please select from the following options"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Change email", style: .default, handler: { (action) in
                self.goToUpdateEmail()
            }))
            alert.addAction(UIAlertAction(title: "Change password", style: .default, handler: { (action) in
                self.goToUpdatePassword(nil)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if let cell = tableView.cellForRow(at: indexPath) {
                alert.popoverPresentationController?.sourceView = cell
                alert.popoverPresentationController?.sourceRect = cell.frame
            }
            present(alert, animated: true, completion: nil)
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
        guard MFMailComposeViewController.canSendMail() else { return }
        
        let title = "RollCall Feedback"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let org = OrganizationService.shared.current.value?.name ?? ""
        let message = "Organization: \(org)\nVersion: \(version)";
        let composer = MFMailComposeViewController(rootViewController: self)
        composer.delegate = self
        composer.setSubject(title)
        composer.setToRecipients(["bobby@renderapps.io"])
        composer.setMessageBody(message, isHTML: false)
        present(composer, animated: true, completion: nil)
    }
    
    func goToUpdateOrganizationName() {
        let orgId = OrganizationService.shared.current.value?.id
        let orgName = OrganizationService.shared.current.value?.name ?? ""
        let title = "Organization: \(orgName)"
        let message = "Please enter new organization name"
        inputPrompt(title: title, message: message) { (newName) in
            guard let name = newName else { return }
            OrganizationService.shared.current.value?.name = name

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
                    LoggingService.log(event: .updateOrganizationEmail, info: ["id": OrganizationService.shared.current.value?.id ?? ""], error: error)
                } else {
                    self.simpleAlert("Email login updated", message: "Your new login and email is \(newEmail)")
                    LoggingService.log(event: .updateOrganizationEmail, info: ["id": OrganizationService.shared.current.value?.id ?? "", "email": newEmail])
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
                LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.current.value?.id ?? "", "error": "Password confirmation did not match"])
                return
            }
            AuthService.currentUser?.updatePassword(to: password, completion: { (error) in
                if let error = error as NSError? {
                    self.simpleAlert("Could not update password", defaultMessage: "Your password could not be updated.", error: error)
                    LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.current.value?.id ?? ""], error: error)
                } else {
                    self.simpleAlert("Password updated", message: nil)
                    LoggingService.log(event: .updateOrganizationPassword, info: ["id": OrganizationService.shared.current.value?.id ?? ""])
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
        cameraHelper?.takeOrSelectPhoto(from: self)
    }
    
    func uploadPhoto(image: UIImage) {
        guard let org = OrganizationService.shared.current.value else { return }
        showProgress("Saving new logo")
        print("FirebaseImageService: uploading org photo for \(org.id)")
        FirebaseImageService.uploadImage(image: image, type: "organization", uid: org.id, progressHandler: { (progress) in
            self.updateProgress(percent: progress)
        }) { [weak self] (url) in
            if let url = url {
                org.photoUrl = url
                print("FirebaseImageService: uploading org photo complete with url \(url)")
                LoggingService.log(event: .updateOrganizationLogo, info: ["title": org.id])
            } else {
                // failure
                self?.simpleAlert("Upload failed", message: "There was an error uploading a new logo.")
            }
            self?.hideProgress()
        }
    }
}
