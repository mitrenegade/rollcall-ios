//
//  SettingsViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation
import RACameraHelper

extension SettingsViewController {
    func notifyForLogoutInSuccess() {
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
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
        cameraHelper.delegate = self
    }
    
    func goToUpdateLogo() {
        print("UpdateLogo")
        cameraHelper.takeOrSelectPhoto(from: self)
    }
    
    func uploadPhoto(image: UIImage) {
        guard let org = OrganizationService.shared.current.value else { return }
        showProgress("Saving new logo")
        print("FirebaseImageService: uploading org photo for \(org.id)")
        FirebaseImageService.uploadImage(image: image, type: "organization", uid: org.id, progressHandler: { (progress) in
            self.updateProgress(Float(progress))
        }) { [weak self] (url) in
            if let url = url {
                org.photoUrl = url
                print("FirebaseImageService: uploading org photo complete with url \(url)")
                ParseLog.log(typeString: "UpdateOrganizationLogo", title: org.id, message: nil, params: nil, error: nil)
            } else {
                // failure
                self?.simpleAlert("Upload failed", message: "There was an error uploading a new logo.")
            }
            self?.hideProgress()
        }
    }
}
