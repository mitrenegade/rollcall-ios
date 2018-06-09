//
//  SettingsViewController+Utils.swift
//  cwsfroster
//
//  Created by Bobby Ren on 1/28/17.
//  Copyright © 2017 Bobby Ren. All rights reserved.
//

import Foundation

extension SettingsViewController {
    func notifyForLogoutInSuccess() {
        self.notify(.LogoutSuccess, object: nil, userInfo: nil)
    }
}

extension SettingsViewController: CameraHelperDelegate {
    func didCancelSelection() {
        
    }
    
    func didCancelPicker() {
        //        [ParseLog logWithTypeString:@"OrganizationImageChanged" title:[[Organization current] objectId] message:nil params:nil error:error];
    }
    
    func didSelectPhoto(selected: UIImage?) {
        //        [ParseLog logWithTypeString:@"OrganizationImageChanged" title:[org objectId] message:nil params:nil error:nil];
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
        cameraHelper.root = self
    }
    
    func goToUpdateLogo() {
        print("UpdateLogo")
        cameraHelper.takeOrSelectPhoto()
//        [ParseLog logWithTypeString:@"UpdateOrganizationLogo" title:[[Organization current] objectId] message:nil params:nil error:nil];
    }
    
    func uploadPhoto(image: UIImage) {
        guard let org = OrganizationService.shared.current.value else { return }
        showProgress("Saving new logo")
        FirebaseImageService.uploadImage(image: image, type: "organization", uid: org.id, progressHandler: { (progress) in
            self.updateProgress(Float(progress))
        }) { (url) in
            if let url = url {
                org.photoUrl = url
            }
            //        // failure
            //        progress.labelText = @"Upload failed";
            //        progress.mode = MBProgressHUDModeText;
            self.hideProgress()
        }
    }
}
